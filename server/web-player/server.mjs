import http from 'node:http';
import { randomBytes } from 'node:crypto';
import { chmodSync } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { ResolverQueue, contentIdentity } from './resolver.mjs';
import { readLimited, rewritePlaylist, upstream } from './network.mjs';

const base = process.env.PUBLIC_URL || 'https://api.vexellab.com/veil-player';
const supabase = process.env.SUPABASE_URL;
const anon = process.env.SUPABASE_ANON_KEY;
const origins = new Set((process.env.ALLOWED_ORIGINS || 'https://veil-12353.web.app,https://veil-12353.firebaseapp.com,https://veil.is-live.dev,https://veil.vexellab.com').split(',').map(origin => origin.trim()));
const queue = new ResolverQueue();
const sessions = new Map();
const rates = new Map();
const token = () => randomBytes(24).toString('base64url');
const expire = () => {
  const now = Date.now();
  for (const [id, session] of sessions) if (now - session.touched > 30 * 60000 || now - session.created > 6 * 3600000) sessions.delete(id);
  for (const [id, rate] of rates) if (now - rate.at > 60000) rates.delete(id);
};
setInterval(expire, 60000).unref();
function limited(id, max) {
  const now = Date.now();
  let rate = rates.get(id);
  if (!rate || now - rate.at > 60000) { rate = { at: now, count: 0 }; rates.set(id, rate); }
  return ++rate.count > max;
}
async function authenticate(req) {
  if (!supabase || !anon) throw Object.assign(new Error('Player service not configured'), { status: 503 });
  const authorization = req.headers.authorization;
  if (!authorization?.startsWith('Bearer ') || authorization.length > 8192) throw Object.assign(new Error('Please sign in again.'), { status: 401 });
  const headers = { apikey: anon, authorization };
  const response = await fetch(`${supabase}/auth/v1/user`, { headers, signal: AbortSignal.timeout(5000) });
  if (!response.ok) throw Object.assign(new Error('Please sign in again.'), { status: 401 });
  const user = await response.json();
  const profile = await fetch(`${supabase}/rest/v1/user_profiles?user_id=eq.${encodeURIComponent(user.id)}&select=is_premium`, { headers, signal: AbortSignal.timeout(5000) });
  if (!profile.ok || !(await profile.json())[0]?.is_premium) throw Object.assign(new Error('Premium playback required.'), { status: 403 });
  return user.id;
}
function register(session, url) {
  const existing = session.reverse.get(url);
  if (existing) return `${base}/session/${session.id}/${existing}`;
  if (session.resources.size >= 5000) throw new Error('Playback resource limit');
  const id = token(); session.resources.set(id, url); session.reverse.set(url, id);
  return `${base}/session/${session.id}/${id}`;
}
const server = http.createServer(async (req, res) => {
  const origin = req.headers.origin;
  if (origin && !origins.has(origin)) { res.writeHead(403); res.end(); return; }
  res.setHeader('Vary', 'Origin');
  if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'authorization, content-type, range');
  res.setHeader('Access-Control-Expose-Headers', 'content-range, accept-ranges, content-length');
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Referrer-Policy', 'no-referrer');
  const json = (status, data) => { res.writeHead(status, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(data)); };
  try {
    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }
    const path = new URL(req.url, 'http://localhost').pathname.replace(/^\/veil-player/, '');
    if (path === '/health' && req.method === 'GET') { json(200, { status: 'ok', provider: 'cinesrc' }); return; }
    if (path === '/resolve' && req.method === 'POST') {
      expire();
      if (rates.size > 10000 || limited(`ip:${req.headers['x-real-ip'] || req.socket.remoteAddress}`, 20)) { json(429, { error: 'Too many requests. Please retry shortly.' }); return; }
      const user = await authenticate(req);
      if (limited(`user:${user}`, 6)) { json(429, { error: 'Too many playback requests. Please retry shortly.' }); return; }
      const input = JSON.parse((await readLimited(req, 2048)).toString());
      try { contentIdentity(input); } catch { json(400, { error: 'Invalid title or unsupported player.' }); return; }
      if (sessions.size >= 30) { json(429, { error: 'Player busy. Please retry shortly.' }); return; }
      const source = await queue.get(input);
      if (res.destroyed) return;
      if (sessions.size >= 30) { json(429, { error: 'Player busy. Please retry shortly.' }); return; }
      const session = { ...source, id: token(), created: Date.now(), touched: Date.now(), resources: new Map(), reverse: new Map(), active: 0 };
      sessions.set(session.id, session);
      json(200, { url: register(session, source.url), provider: 'cinesrc', format: 'hls' }); return;
    }
    const closing = /^\/session\/([\w-]+)$/.exec(path);
    if (closing && req.method === 'DELETE') {
      // Possession of the random session capability permits revoking it.
      sessions.delete(closing[1]); res.writeHead(204); res.end(); return;
    }
    const match = /^\/session\/([\w-]+)\/([\w-]+)$/.exec(path);
    if (match && ['GET', 'HEAD'].includes(req.method)) {
      expire();
      const session = sessions.get(match[1]);
      const target = session?.resources.get(match[2]);
      if (!target) { json(410, { error: 'Playback session expired. Please reopen the player.' }); return; }
      if (session.active >= 8) { json(429, { error: 'Too many media requests' }); return; }
      session.active++; session.touched = Date.now();
      try {
        const headers = { ...session.headers };
        if (new URL(target).origin !== new URL(session.url).origin) { delete headers.cookie; delete headers.authorization; }
        if (req.headers.range) {
          if (!/^bytes=\d+-\d*$/.test(req.headers.range)) { json(400, { error: 'Invalid range' }); return; }
          headers.range = req.headers.range;
        }
        const { response, url } = await upstream(target, headers);
        if (response.statusCode >= 400) { const status = response.statusCode; response.destroy(); json(status, { error: 'Media source unavailable. Please retry playback.' }); return; }
        const playlist = /mpegurl/i.test(response.headers['content-type'] || '') || /\.m3u8(?:$|\?)/.test(url.href) || url.pathname.includes('/api/playlist/');
        if (req.method === 'HEAD') { res.writeHead(response.statusCode, { 'Content-Type': playlist ? 'application/vnd.apple.mpegurl' : 'application/octet-stream' }); response.destroy(); res.end(); return; }
        if (playlist) {
          const body = rewritePlaylist((await readLimited(response)).toString(), url, link => register(session, link));
          res.writeHead(200, { 'Content-Type': 'application/vnd.apple.mpegurl' }); res.end(body);
        } else {
          const outgoing = { 'Content-Type': 'application/octet-stream' };
          for (const key of ['content-range', 'accept-ranges', 'content-length']) if (response.headers[key]) outgoing[key] = response.headers[key];
          res.writeHead(response.statusCode, outgoing);
          await pipeline(response, res);
        }
      } finally { session.active--; }
      return;
    }
    json(404, { error: 'Not found' });
  } catch (error) {
    // Never log signed media URLs, cookies, access tokens or raw upstream errors.
    if (!res.headersSent && !res.destroyed) json(error.status || 502, { error: error.status ? error.message : 'Could not prepare playback. Please retry.' });
    else res.destroy();
  }
});
server.requestTimeout = 15000;
server.headersTimeout = 10000;
server.on('listening', () => process.send?.({ address: server.address() }));
if (process.env.SOCKET_PATH) {
  server.listen(process.env.SOCKET_PATH, () => chmodSync(process.env.SOCKET_PATH, 0o660));
} else {
  server.listen(Number(process.env.PORT || 8018), '127.0.0.1');
}

import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { fork } from 'node:child_process';
import { once } from 'node:events';
import { publicAddress, publicTarget, rewritePlaylist } from './network.mjs';
import { contentIdentity, ResolverQueue } from './resolver.mjs';

test('rejects private, mapped and reserved addresses', async () => {
  for (const ip of ['127.0.0.1', '10.0.0.1', '192.168.1.1', '169.254.169.254', '::1', '::ffff:127.0.0.1', 'fc00::1', '0.0.0.0']) assert.equal(publicAddress(ip), false, ip);
  assert.equal(publicAddress('8.8.8.8'), true);
  await assert.rejects(publicTarget('https://127.0.0.1/file'));
  await assert.rejects(publicTarget('http://example.com/file'));
  await assert.rejects(publicTarget('https://example.com:8000/file'));
});
test('rewrites variant, segment and key URLs without exposing upstream tokens', () => {
  const urls = [];
  const result = rewritePlaylist('#EXTM3U\n#EXT-X-KEY:METHOD=AES-128,URI="key?token=secret"\n#EXTINF:5,\nchunk.ts\n', 'https://cdn.test/path/index.m3u8', url => { urls.push(url); return `/opaque/${urls.length}`; });
  assert.equal(urls[0], 'https://cdn.test/path/key?token=secret');
  assert.equal(urls[1], 'https://cdn.test/path/chunk.ts');
  assert.ok(result.includes('URI="/opaque/1"'));
  assert.ok(!result.includes('secret'));
});
test('identity rejects Player 2 and invalid episode data', () => {
  assert.throws(() => contentIdentity({ provider: 'vidsrc', type: 'movie', id: 1 }));
  assert.throws(() => contentIdentity({ provider: 'cinesrc', type: 'tv', id: 1, season: -1, episode: 2 }));
  assert.equal(contentIdentity({ provider: 'cinesrc', type: 'tv', id: 1, season: 2, episode: 3 }), 'tv:1:2:3');
});
test('resolver serializes work, caps queue and caches by content', async () => {
  let active = 0, peak = 0, calls = 0;
  const queue = new ResolverQueue(async input => {
    calls++; active++; peak = Math.max(peak, active);
    await new Promise(resolve => setTimeout(resolve, 10)); active--;
    return { url: `https://cdn.test/${input.id}`, resolvedAt: Date.now() };
  });
  const input = id => ({ provider: 'cinesrc', type: 'movie', id });
  const work = [queue.get(input(1)), queue.get(input(1)), queue.get(input(2))];
  await assert.rejects(queue.get(input(3)), { status: 429 });
  await Promise.all(work);
  assert.equal(peak, 1); assert.equal(calls, 2);
  await queue.get(input(2)); assert.equal(calls, 2);
});
test('HTTP contract enforces auth, premium, origin and provider', async () => {
  const auth = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    if (req.headers.authorization === 'Bearer expired') { res.writeHead(401); res.end('{}'); return; }
    if (!req.url.startsWith('/auth/')) assert.equal(new URL(req.url, 'http://localhost').searchParams.get('user_id'), 'eq.test-user');
    res.end(req.url.startsWith('/auth/') ? '{"id":"test-user"}' : JSON.stringify([{ is_premium: req.headers.authorization === 'Bearer premium' }]));
  });
  auth.listen(0, '127.0.0.1'); await once(auth, 'listening');
  const child = fork(new URL('./server.mjs', import.meta.url), { env: { ...process.env, PORT: '0', SOCKET_PATH: '', SUPABASE_URL: `http://127.0.0.1:${auth.address().port}`, SUPABASE_ANON_KEY: 'test' }, stdio: ['ignore', 'ignore', 'inherit', 'ipc'] });
  try {
    const [message] = await once(child, 'message');
    const base = `http://127.0.0.1:${message.address.port}`;
    assert.equal((await fetch(`${base}/health`)).status, 200);
    const request = headers => fetch(`${base}/resolve`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: JSON.stringify({ id: 1, type: 'movie', provider: 'vidsrc' }) });
    assert.equal((await request({})).status, 401);
    assert.equal((await request({ Authorization: 'Bearer expired' })).status, 401);
    assert.equal((await request({ Authorization: 'Bearer free' })).status, 403);
    assert.equal((await request({ Authorization: 'Bearer premium', Origin: 'https://evil.test' })).status, 403);
    assert.equal((await request({ Authorization: 'Bearer premium' })).status, 400);
    assert.equal((await fetch(`${base}/session/unknown/unknown`)).status, 410);
    const preflight = await fetch(`${base}/resolve`, { method: 'OPTIONS', headers: { Origin: 'https://veil-12353.web.app' } });
    assert.equal(preflight.status, 204);
    assert.equal(preflight.headers.get('access-control-allow-origin'), 'https://veil-12353.web.app');
    for (const origin of ['https://veil.is-live.dev', 'https://veil.vexellab.com']) {
      const response = await fetch(`${base}/resolve`, { method: 'OPTIONS', headers: { Origin: origin } });
      assert.equal(response.status, 204);
      assert.equal(response.headers.get('access-control-allow-origin'), origin);
    }
  } finally { child.kill(); auth.closeAllConnections(); await new Promise(resolve => auth.close(resolve)); }
});

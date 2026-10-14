// Local-only bridge for integration_test/playback_live_test.dart.
// Supply credentials via environment variables; they are never written to disk.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import dns from 'node:dns/promises';
import {execFileSync} from 'node:child_process';

const root = path.resolve(process.env.VEIL_TEST_EVIDENCE_DIR || 'build/playback-evidence');
const simulator = process.env.VEIL_TEST_SIMULATOR_ID || 'booted';
const port = Number(process.env.VEIL_TEST_BRIDGE_PORT || 18765);
fs.mkdirSync(root, {recursive: true});

const cases = [
  {key: 'fall-2', title: 'Fall 2: Deadpoint', type: 'movie', id: 1101412},
  {key: 'interstellar', title: 'Interstellar', type: 'movie', id: 157336},
  {key: 'dune-2', title: 'Dune: Part Two', type: 'movie', id: 693134},
  {key: 'avatar', title: 'Avatar', type: 'movie', id: 19995},
  {key: 'breaking-bad-s1e1', title: 'Breaking Bad S1E1', type: 'tv', id: 1396, season: 1, episode: 1},
  {key: 'got-s2e3', title: 'Game of Thrones S2E3', type: 'tv', id: 1399, season: 2, episode: 3},
  {key: 'arcane-s2e3', title: 'Arcane S2E3', type: 'tv', id: 94605, season: 2, episode: 3},
];

async function readJson(request) {
  let body = '';
  for await (const chunk of request) {
    body += chunk;
    if (body.length > 2 * 1024 * 1024) throw new Error('Payload too large');
  }
  return JSON.parse(body);
}

function privateAddress(address) {
  if (address.includes(':')) {
    return address === '::' || address === '::1' || /^(fc|fd|fe80|::ffff:)/i.test(address);
  }
  const [a, b] = address.split('.').map(Number);
  return a === 0 || a === 10 || a === 127 || a >= 224 ||
    (a === 169 && b === 254) || (a === 172 && b >= 16 && b <= 31) ||
    (a === 192 && b === 168) || (a === 100 && b >= 64 && b <= 127);
}

async function probeStream(input) {
  const url = new URL(input.url);
  if (url.protocol !== 'https:' || url.username || url.password) {
    throw new Error('Only public HTTPS media URLs can be probed');
  }
  const addresses = await dns.lookup(url.hostname, {all: true});
  if (!addresses.length || addresses.some(entry => privateAddress(entry.address))) {
    throw new Error('Private destinations cannot be probed');
  }
  const start = Date.now();
  const response = await fetch(url, {
    headers: {Range: 'bytes=0-2047', Referer: input.referer, 'User-Agent': input.ua},
    redirect: 'manual',
    signal: AbortSignal.timeout(10000),
  });
  const reader = response.body?.getReader();
  const first = reader ? await reader.read() : {};
  await reader?.cancel();
  const bytes = Buffer.from(first.value || []).subarray(0, 64);
  return {
    url: url.origin + url.pathname,
    status: response.status,
    mime: response.headers.get('content-type'),
    range: response.headers.get('content-range'),
    length: response.headers.get('content-length'),
    ms: Date.now() - start,
    prefix: bytes.toString('hex'),
    text: bytes.toString('utf8').replace(/[^\x20-\x7e]/g, '.'),
  };
}

http.createServer(async (request, response) => {
  response.setHeader('content-type', 'application/json');
  // Browser pages must not consume the credential bridge.
  if (request.headers.origin) {
    response.writeHead(403).end(JSON.stringify({error: 'Browser origins are not allowed'}));
    return;
  }
  try {
    if (request.url === '/credentials' && request.method === 'GET') {
      const email = process.env.VEIL_TEST_EMAIL;
      const password = process.env.VEIL_TEST_PASSWORD;
      if (!email || !password) {
        response.writeHead(400).end(JSON.stringify({error: 'Set VEIL_TEST_EMAIL and VEIL_TEST_PASSWORD'}));
        return;
      }
      response.end(JSON.stringify({email, password}));
      return;
    }
    if (request.url === '/cases' && request.method === 'GET') {
      response.end(JSON.stringify(cases));
      return;
    }
    if (request.url === '/probe-stream' && request.method === 'POST') {
      try {
        response.end(JSON.stringify(await probeStream(await readJson(request))));
      } catch (error) {
        response.end(JSON.stringify({status: 0, error: error.name}));
      }
      return;
    }
    if (request.url === '/result' && request.method === 'POST') {
      const result = await readJson(request);
      const name = `${result.run}-${result.case}-server-${result.server}`.replace(/[^a-z0-9_-]/gi, '_');
      fs.writeFileSync(path.join(root, `${name}.json`), JSON.stringify(result, null, 2));
      try {
        execFileSync('xcrun', ['simctl', 'io', simulator, 'screenshot', path.join(root, `${name}.png`)], {stdio: 'ignore'});
      } catch {
        // JSON evidence is still available when simulator screenshots are unsupported.
      }
      console.log(JSON.stringify({run: result.run, case: result.case, server: result.server,
        playing: result.playing, startMs: result.firstPlayingMs, seek: result.seekSucceeded}));
      response.end(JSON.stringify({saved: true}));
      return;
    }
    response.writeHead(404).end(JSON.stringify({error: 'Unknown endpoint'}));
  } catch {
    response.writeHead(400).end(JSON.stringify({error: 'Invalid probe request'}));
  }
}).listen(port, '127.0.0.1', () => {
  console.log(`Playback bridge listening on loopback port ${port}; evidence: ${root}`);
});

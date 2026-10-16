import { resolve } from './resolver.mjs';
import { upstream, readLimited } from './network.mjs';

const input = process.argv[2] === 'tv'
  ? { provider: 'cinesrc', type: 'tv', id: 1396, season: 1, episode: 1 }
  : { provider: 'cinesrc', type: 'movie', id: 157336 };
const source = await resolve(input);
console.log(JSON.stringify({ event: 'resolved', type: input.type, host: new URL(source.url).host }));
let target = source.url;
for (let depth = 0; depth < 3; depth++) {
  const headers = { ...source.headers };
  if (new URL(target).origin !== new URL(source.url).origin) { delete headers.cookie; delete headers.authorization; }
  const { response, url } = await upstream(target, headers);
  console.log(JSON.stringify({ event: 'resource', depth, status: response.statusCode, host: url.host }));
  if (response.statusCode !== 200) { response.destroy(); process.exitCode = 1; break; }
  if (depth === 2) { response.destroy(); break; }
  const body = (await readLimited(response)).toString();
  if (!body.startsWith('#EXTM3U')) { process.exitCode = 1; break; }
  const next = body.split('\n').map(s => s.trim()).find(s => s && !s.startsWith('#'));
  if (!next) { process.exitCode = 1; break; }
  target = new URL(next, url).href;
}

import https from 'node:https';
import { lookup } from 'node:dns/promises';
import ipaddr from 'ipaddr.js';

export function publicAddress(address) {
  try {
    let ip = ipaddr.parse(address);
    if (ip.kind() === 'ipv6' && ip.isIPv4MappedAddress()) ip = ip.toIPv4Address();
    return ip.range() === 'unicast';
  } catch { return false; }
}
export async function publicTarget(raw) {
  const url = new URL(raw);
  if (url.protocol !== 'https:' || url.username || url.password || (url.port && url.port !== '443')) throw new Error('Invalid media destination');
  const addresses = await lookup(url.hostname, { all: true });
  if (!addresses.length || addresses.some(a => !publicAddress(a.address))) throw new Error('Private media destination');
  return { url, address: addresses.find(a => a.family === 4) ?? addresses[0] };
}

export async function upstream(raw, headers = {}, redirects = 0, credentialOrigin = new URL(raw).origin) {
  const { url, address } = await publicTarget(raw);
  const safeHeaders = { ...headers, 'accept-encoding': 'identity' };
  if (url.origin !== credentialOrigin) { delete safeHeaders.cookie; delete safeHeaders.authorization; }
  // Pin the validated DNS answer for the TLS connection (DNS rebinding defense).
  const response = await new Promise((resolve, reject) => {
    const request = https.get(url, {
      headers: safeHeaders, agent: false,
      lookup: (_host, options, callback) => options.all
        ? callback(null, [address]) : callback(null, address.address, address.family),
    }, resolve);
    request.setTimeout(15000, () => request.destroy(new Error('Upstream timeout')));
    request.on('error', reject);
  });
  if ([301, 302, 303, 307, 308].includes(response.statusCode)) {
    response.destroy();
    if (redirects >= 3 || !response.headers.location) throw new Error('Invalid media redirect');
    return upstream(new URL(response.headers.location, url).href, safeHeaders, redirects + 1, credentialOrigin);
  }
  return { response, url };
}
export async function readLimited(stream, limit = 4 * 1024 * 1024) {
  const chunks = []; let bytes = 0;
  for await (const chunk of stream) {
    bytes += chunk.length;
    if (bytes > limit) { stream.destroy(); throw new Error('Response too large'); }
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}
export function rewritePlaylist(body, base, register) {
  if (!body.trimStart().startsWith('#EXTM3U')) throw new Error('Invalid playlist');
  return body.split('\n').map(line => {
    if (!line.trim()) return line;
    const rewrite = path => register(new URL(path, base).href);
    return line.startsWith('#') ? line.replace(/URI="([^"]+)"/g, (_, uri) => `URI="${rewrite(uri)}"`) : rewrite(line.trim());
  }).join('\n');
}

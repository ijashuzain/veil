const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS, HEAD',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, range',
  'Access-Control-Expose-Headers':
    'content-length, content-range, accept-ranges, content-type',
};

const defaultAllowedHosts = ['test-streams.mux.dev'];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return new Response('Method not allowed', {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const url = new URL(req.url);
    const targetUrl = url.searchParams.get('url');

    if (!targetUrl) {
      return new Response('Missing url parameter', { status: 400, headers: corsHeaders });
    }

    const target = new URL(targetUrl);
    if (target.protocol !== 'https:' && target.protocol !== 'http:') {
      return new Response('Unsupported target protocol', {
        status: 400,
        headers: corsHeaders,
      });
    }

    // Temporarily allow any HTTP(S) host while testing playback sources.
    // if (!isAllowedHost(target.hostname)) {
    //   return new Response('Target host is not allowed', {
    //     status: 403,
    //     headers: corsHeaders,
    //   });
    // }

    const isM3u8 = target.pathname.toLowerCase().endsWith('.m3u8');
    const headers = upstreamHeaders(req);

    const proxyReq = new Request(target, {
      method: req.method,
      headers: headers,
      redirect: 'manual',
    });

    const response = await fetch(proxyReq);

    if (!isM3u8) {
      const responseHeaders = new Headers(response.headers);
      for (const [key, value] of Object.entries(corsHeaders)) {
        responseHeaders.set(key, value);
      }
      return new Response(req.method === 'HEAD' ? null : response.body, {
        status: response.status,
        headers: responseHeaders,
      });
    }

    const body = req.method === 'HEAD'
      ? ''
      : rewritePlaylist(await response.text(), target, url, req);

    const responseHeaders = new Headers(response.headers);
    for (const [key, value] of Object.entries(corsHeaders)) {
      responseHeaders.set(key, value);
    }
    responseHeaders.set('content-type', 'application/vnd.apple.mpegurl; charset=utf-8');
    responseHeaders.delete('content-length');

    return new Response(req.method === 'HEAD' ? null : body, {
      status: response.status,
      headers: responseHeaders,
    });
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : 'Unknown error';
    return new Response(`Proxy Error: ${errorMsg}`, { status: 500, headers: corsHeaders });
  }
});

function isAllowedHost(hostname: string): boolean {
  const configuredHosts = Deno.env.get('HLS_PROXY_ALLOWED_HOSTS')
    ?.split(',')
    .map((host) => host.trim().toLowerCase())
    .filter(Boolean);
  const allowedHosts = configuredHosts?.length ? configuredHosts : defaultAllowedHosts;
  const host = hostname.toLowerCase();

  return allowedHosts.some((allowedHost) =>
    host === allowedHost || host.endsWith(`.${allowedHost}`)
  );
}

function upstreamHeaders(req: Request): Headers {
  const headers = new Headers();
  const range = req.headers.get('range');
  const accept = req.headers.get('accept');
  const userAgent = req.headers.get('user-agent');

  if (range) headers.set('range', range);
  if (accept) headers.set('accept', accept);
  if (userAgent) headers.set('user-agent', userAgent);

  return headers;
}

function rewritePlaylist(
  playlist: string,
  target: URL,
  requestUrl: URL,
  req: Request,
): string {
  const proxyBase = proxyBaseUrl(requestUrl, req);
  const proxyUrl = (value: string) =>
    `${proxyBase}${encodeURIComponent(new URL(value, target.href).href)}`;

  return playlist
    .split('\n')
    .map((line) => {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) {
        return line.replace(/URI="([^"]+)"/g, (_match, uri) => {
          return `URI="${proxyUrl(uri)}"`;
        });
      }

      const indentation = line.slice(0, line.indexOf(trimmed));
      return `${indentation}${proxyUrl(trimmed)}`;
    })
    .join('\n');
}

function proxyBaseUrl(requestUrl: URL, req: Request): string {
  const proto = req.headers.get('x-forwarded-proto') ?? requestUrl.protocol.replace(':', '');
  const host =
    requestUrl.host || req.headers.get('host') || req.headers.get('x-forwarded-host');
  const pathname = requestUrl.pathname.startsWith('/functions/v1/')
    ? requestUrl.pathname
    : `/functions/v1${requestUrl.pathname}`;

  return `${proto}://${host}${pathname}?url=`;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS, HEAD',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const tmdbImageOrigin = 'https://image.tmdb.org';
const allowedSizes = new Set([
  'original',
  'w92',
  'w154',
  'w185',
  'w342',
  'w500',
  'w780',
  'w1280',
]);

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return textResponse('Method not allowed', 405);
  }

  const requestUrl = new URL(req.url);
  const imagePath = tmdbImagePath(requestUrl.pathname);
  if (!imagePath || !isAllowedImagePath(imagePath)) {
    return textResponse('TMDB image path is not allowed', 403);
  }

  try {
    const upstreamResponse = await fetch(`${tmdbImageOrigin}${imagePath}`, {
      method: req.method,
      headers: { accept: req.headers.get('accept') ?? 'image/*' },
    });
    const headers = responseHeaders(upstreamResponse);
    return new Response(req.method === 'HEAD' ? null : upstreamResponse.body, {
      status: upstreamResponse.status,
      headers,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return textResponse(`TMDB image request failed: ${message}`, 502);
  }
});

function tmdbImagePath(pathname: string): string | null {
  const marker = '/tmdb-image';
  const markerIndex = pathname.indexOf(marker);
  if (markerIndex < 0) return null;

  const path = pathname.slice(markerIndex + marker.length);
  if (!path.startsWith('/t/p/')) return null;
  return path;
}

function isAllowedImagePath(path: string): boolean {
  const segments = path.split('/').filter(Boolean);
  if (segments.length < 4) return false;
  if (segments[0] !== 't' || segments[1] !== 'p') return false;
  if (!allowedSizes.has(segments[2])) return false;
  return segments.slice(3).every((segment) => segment && segment !== '..');
}

function responseHeaders(response: Response): Headers {
  const headers = new Headers(corsHeaders);
  const contentType = response.headers.get('content-type');
  const etag = response.headers.get('etag');
  const cacheControl = response.status >= 400
    ? 'no-store'
    : 'public, max-age=86400, s-maxage=604800';

  headers.set('cache-control', cacheControl);
  if (contentType) headers.set('content-type', contentType);
  if (etag) headers.set('etag', etag);
  return headers;
}

function textResponse(body: string, status: number): Response {
  const headers = new Headers(corsHeaders);
  headers.set('content-type', 'text/plain; charset=utf-8');
  headers.set('cache-control', 'no-store');
  return new Response(body, { status, headers });
}

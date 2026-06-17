const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const tmdbOrigin = 'https://api.themoviedb.org';
const allowedRoutes = new Set([
  'configuration',
  'discover',
  'find',
  'genre',
  'movie',
  'search',
  'trending',
  'tv',
]);

type TmdbAuth =
  | { readAccessToken: string; apiKey?: never }
  | { readAccessToken?: never; apiKey: string }
  | null;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'GET') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const tmdbAuth = tmdbAuthentication();
  if (!tmdbAuth) {
    return jsonResponse(
      { error: 'TMDB_READ_ACCESS_TOKEN or TMDB_API_KEY is not configured' },
      500,
    );
  }

  const requestUrl = new URL(req.url);
  const tmdbPath = tmdbApiPath(requestUrl.pathname);
  if (!tmdbPath || !isAllowedTmdbPath(tmdbPath)) {
    return jsonResponse({ error: 'TMDB path is not allowed' }, 403);
  }

  const targetUrl = new URL(`${tmdbOrigin}${tmdbPath}`);
  for (const [key, value] of requestUrl.searchParams) {
    if (key.toLowerCase() === 'api_key') continue;
    targetUrl.searchParams.append(key, value);
  }
  if (tmdbAuth.apiKey) {
    targetUrl.searchParams.set('api_key', tmdbAuth.apiKey);
  }

  try {
    const upstreamHeaders = new Headers({ accept: 'application/json' });
    if (tmdbAuth.readAccessToken) {
      upstreamHeaders.set(
        'authorization',
        `Bearer ${tmdbAuth.readAccessToken}`,
      );
    }

    const upstreamResponse = await fetch(targetUrl, {
      headers: upstreamHeaders,
    });

    const headers = responseHeaders(upstreamResponse, tmdbPath);
    return new Response(upstreamResponse.body, {
      status: upstreamResponse.status,
      headers,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return jsonResponse({ error: 'TMDB request failed', message }, 502);
  }
});

function tmdbApiPath(pathname: string): string | null {
  const marker = '/tmdb';
  const markerIndex = pathname.indexOf(marker);
  if (markerIndex < 0) return null;

  const path = pathname.slice(markerIndex + marker.length);
  if (!path.startsWith('/3/')) return null;
  return path;
}

function isAllowedTmdbPath(path: string): boolean {
  const segments = path.split('/').filter(Boolean);
  if (segments.length < 2 || segments[0] !== '3') return false;
  return allowedRoutes.has(segments[1]);
}

function tmdbAuthentication(): TmdbAuth {
  const readAccessToken = Deno.env.get('TMDB_READ_ACCESS_TOKEN')?.trim();
  if (readAccessToken) return { readAccessToken };

  const apiKey = Deno.env.get('TMDB_API_KEY')?.trim();
  if (apiKey) return { apiKey };

  return null;
}

function responseHeaders(response: Response, tmdbPath: string): Headers {
  const headers = new Headers(corsHeaders);
  const contentType = response.headers.get('content-type');
  const etag = response.headers.get('etag');

  headers.set('cache-control', cacheControlFor(tmdbPath, response.status));
  headers.set('vary', 'Origin');
  if (contentType) headers.set('content-type', contentType);
  if (etag) headers.set('etag', etag);

  return headers;
}

function cacheControlFor(tmdbPath: string, status: number): string {
  if (status >= 400) return 'no-store';

  if (
    tmdbPath.startsWith('/3/configuration') ||
    tmdbPath.startsWith('/3/genre')
  ) {
    return 'public, max-age=86400, s-maxage=604800';
  }

  if (tmdbPath.startsWith('/3/search')) {
    return 'public, max-age=60, s-maxage=300';
  }

  if (tmdbPath.startsWith('/3/movie/') || tmdbPath.startsWith('/3/tv/')) {
    return 'public, max-age=3600, s-maxage=86400';
  }

  return 'public, max-age=300, s-maxage=900';
}

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  const headers = new Headers(corsHeaders);
  headers.set('content-type', 'application/json; charset=utf-8');
  headers.set('cache-control', 'no-store');

  return new Response(JSON.stringify(body), { status, headers });
}

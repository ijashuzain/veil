// Adapter for bipuldey19/Opensubtitles-Unofficial-API. Configure a working,
// self-hosted instance; the repository's advertised public host is offline.
export function safeFallbackDownload(raw: unknown): URL | null {
  if (typeof raw !== 'string') return null;
  try {
    const url = new URL(raw);
    if (url.protocol !== 'https:' || url.port || url.username || url.password) return null;
    if (!(url.hostname === 'opensubtitles.org' || url.hostname.endsWith('.opensubtitles.org'))) return null;
    if (!/^\/(?:[a-z]{2}\/subtitleserve\/sub|(?:[a-z]{2}\/)?download\/sub)\/\d+\/?$/.test(url.pathname)) return null;
    return url;
  } catch { return null; }
}

export async function searchFallback(params: URLSearchParams) {
  const base = Deno.env.get('SUBTITLE_FALLBACK_API_URL');
  const title = params.get('title')?.trim();
  if (!base || !title || title.length > 200) return [];
  try {
    const root = new URL(base);
    if (root.protocol !== 'https:' || root.username || root.password) return [];
    const url = new URL('/api/all/search', root);
    const tv = params.get('type') === 'episode';
    url.searchParams.set('q', title);
    url.searchParams.set('type', tv ? 'series' : 'movies');
    if (tv) {
      url.searchParams.set('s', params.get('season')!);
      url.searchParams.set('e', params.get('episode')!);
    }
    const fetchJson = async (target: URL) => {
      const response = await fetch(target, { redirect: 'error', signal: AbortSignal.timeout(8000) });
      if (!response.ok) throw new Error('Fallback unavailable');
      return await response.json();
    };
    let data = await fetchJson(url);
    if (!Array.isArray(data)) return [];
    if (!tv) {
      const normalize = (value: string) => value.toLowerCase().replace(/[^a-z0-9]/g, '');
      // Title search can match unrelated films: require title and year match.
      const match = data.find(row => typeof row.title === 'string' &&
        row.title.includes(`(${params.get('year')})`) &&
        normalize(row.title.split(/\(\d{4}\)/)[0]) === normalize(title) && /^\d+$/.test(String(row.id)));
      if (!match) return [];
      const view = new URL('/api/all/view', root);
      view.searchParams.set('id', String(match.id));
      data = await fetchJson(view);
    }
    if (!Array.isArray(data)) return [];
    return data.flatMap(row => Array.isArray(row.data) ? row.data : []).slice(0, 100).flatMap(row => {
      const download = safeFallbackDownload(row.download);
      if (!download) return [];
      return [{ downloadUrl: download.toString(), language: String(row.language ?? ''), release: String(row.title ?? '').trim(), source: 'OpenSubtitles fallback' }];
    });
  } catch { return []; }
}

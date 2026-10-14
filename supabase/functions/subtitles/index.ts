import { searchFallback, safeFallbackDownload } from './fallback.ts';
import { unzipSync } from 'npm:fflate@0.8.2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const origin = 'https://sub.wyzie.io';
const json = (value: unknown, status = 200) => new Response(JSON.stringify(value), {
  status, headers: { ...cors, 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});

function downloadUrl(raw: unknown): URL | null {
  if (typeof raw !== 'string' || raw.length > 8192) return null;
  try {
    const url = new URL(raw);
    if (url.origin !== origin || url.username || url.password || !/^\/c\/[a-zA-Z0-9_-]+\/id\/[a-zA-Z0-9_-]+$/.test(url.pathname)) return null;
    url.searchParams.delete('key');
    url.hash = '';
    return url;
  } catch { return null; }
}

export async function handleRequest(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'GET') return json({ error: 'Method not allowed' }, 405);
  const authorization = req.headers.get('authorization');
  if (!authorization?.startsWith('Bearer ')) return json({ error: 'Sign in required' }, 401);
  try {
    const user = await fetch(`${Deno.env.get('SUPABASE_URL')}/auth/v1/user`, {
      headers: { authorization, apikey: Deno.env.get('SUPABASE_ANON_KEY') ?? '' },
      signal: AbortSignal.timeout(5000),
    });
    if (!user.ok) return json({ error: 'Sign in required' }, 401);
    const key = Deno.env.get('WYZIE_API_KEY');
    const params = new URL(req.url).searchParams;
    const positive = (value: string | null) => value !== null && /^[1-9]\d{0,9}$/.test(value);
    if (params.get('action') === 'search') {
      const id = params.get('tmdb_id');
      const type = params.get('type');
      if (!positive(id) || !['movie', 'episode'].includes(type ?? '')) return json({ error: 'Invalid title' }, 400);
      const query = new URLSearchParams({ id: id!, format: 'srt,vtt', encoding: 'utf-8', key: key ?? '' });
      if (type === 'episode') {
        if (!positive(params.get('season')) || !positive(params.get('episode'))) return json({ error: 'Invalid episode' }, 400);
        query.set('season', params.get('season')!);
        query.set('episode', params.get('episode')!);
      }
      let data: unknown = [];
      try {
        if (key) {
          const response = await fetch(`${origin}/search?${query}`, { redirect: 'error', signal: AbortSignal.timeout(10000) });
          if (response.ok) data = await response.json();
        }
      } catch { /* Try the independent fallback below. */ }
      if (!Array.isArray(data)) data = [];
      const tracks = (data as Record<string, unknown>[]).slice(0, 200).flatMap(row => {
        const url = downloadUrl(row?.url);
        if (!url || !['srt', 'vtt'].includes(String(row.format).toLowerCase())) return [];
        return [{ downloadUrl: url.toString(), language: String(row.language ?? ''), release: String(row.release ?? ''), source: 'Wyzie' }];
      });
      return json({ tracks: tracks.length > 0 ? tracks : await searchFallback(params) });
    }
    if (params.get('action') === 'download') {
      const wyzie = downloadUrl(params.get('url'));
      const url = wyzie ?? safeFallbackDownload(params.get('url'));
      if (!url) return json({ error: 'Invalid subtitle file' }, 400);
      if (wyzie) {
        if (!key) return json({ error: 'Subtitles not configured' }, 503);
        url.searchParams.set('key', key);
      }
      // Keep the API key on the fixed provider host; never forward user auth.
      let file = await fetch(url, { redirect: 'manual', signal: AbortSignal.timeout(15000) });
      // OpenSubtitles website downloads may redirect to its download subdomain.
      for (let count = 0; !wyzie && file.status >= 300 && file.status < 400 && count < 3; count++) {
        const next = safeFallbackDownload(new URL(file.headers.get('location') ?? '', file.url || url).toString());
        await file.body?.cancel();
        if (!next) return json({ error: 'Invalid download redirect' }, 502);
        file = await fetch(next, { redirect: 'manual', signal: AbortSignal.timeout(8000) });
      }
      if (!file.ok) return json({ error: 'Subtitle download unavailable' }, file.status === 429 ? 429 : 502);
      if (!wyzie) {
        const reader = file.body?.getReader();
        if (!reader) return json({ error: 'Empty subtitle file' }, 502);
        const chunks: Uint8Array[] = [];
        let size = 0;
        while (true) {
          const { value, done } = await reader.read();
          if (done) break;
          size += value.length;
          if (size > 5 * 1024 * 1024) { await reader.cancel(); return json({ error: 'Subtitle too large' }, 502); }
          chunks.push(value);
        }
        const bytes = new Uint8Array(size);
        let offset = 0;
        for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
        let text: string;
        if (bytes[0] === 0x50 && bytes[1] === 0x4b) {
          let selected = false;
          const files = unzipSync(bytes, { filter: entry => {
            if (selected || entry.originalSize > 2 * 1024 * 1024 || !/\.(srt|vtt)$/i.test(entry.name)) return false;
            selected = true;
            return true;
          } });
          const caption = Object.values(files)[0];
          if (!caption) return json({ error: 'Archive has no supported captions' }, 502);
          text = new TextDecoder().decode(caption);
        } else { text = new TextDecoder().decode(bytes); }
        if (!text.includes('-->')) return json({ error: 'Invalid subtitle content' }, 502);
        return new Response(text, { headers: { ...cors, 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-store' } });
      }
      return new Response(file.body, { headers: { ...cors, 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-store' } });
    }
    return json({ error: 'Unknown action' }, 400);
  } catch {
    return json({ error: 'Subtitle service unavailable' }, 502);
  }
}

if (import.meta.main) Deno.serve(handleRequest);

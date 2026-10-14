import { handleRequest } from './index.ts';
import { zipSync, strToU8 } from 'npm:fflate@0.8.2';
function check(condition: boolean, message: string) { if (!condition) throw new Error(message); }
function setup() {
  Deno.env.set('SUPABASE_URL', 'https://auth.test');
  Deno.env.set('SUPABASE_ANON_KEY', 'public-test');
  Deno.env.set('WYZIE_API_KEY', 'private-test-key');
}
const request = (query: string) => new Request(`https://local/subtitles?${query}`, { headers: { Authorization: 'Bearer session' } });

Deno.test('Wyzie failure uses configured fallback and checks title/year', async () => {
  setup();
  Deno.env.set('SUBTITLE_FALLBACK_API_URL', 'https://fallback.test');
  const original = globalThis.fetch;
  globalThis.fetch = ((input: string | URL | Request) => {
    const url = new URL(String(input));
    if (url.hostname === 'auth.test') return Promise.resolve(Response.json({ id: 'user' }));
    if (url.hostname === 'sub.wyzie.io') return Promise.resolve(new Response('', { status: 503 }));
    if (url.pathname.endsWith('/search')) return Promise.resolve(Response.json([{ id: '12', title: 'Different film (2026)' }, { id: '99', title: 'Spider-Man: Brand New Day (2026)' }]));
    check(url.searchParams.get('id') === '99', 'Wrong movie selected');
    return Promise.resolve(Response.json([{ data: [{ title: 'WEB', language: 'English', download: 'https://www.opensubtitles.org/en/subtitleserve/sub/123' }] }]));
  }) as typeof fetch;
  try {
    const result = await handleRequest(request('action=search&type=movie&tmdb_id=969681&title=Spider-Man%3A%20Brand%20New%20Day&year=2026'));
    check((await result.text()).includes('OpenSubtitles fallback'), 'Fallback missing');
  } finally { globalThis.fetch = original; Deno.env.delete('SUBTITLE_FALLBACK_API_URL'); }
});

Deno.test('fallback ZIP is converted to captions without leaking Wyzie key', async () => {
  setup();
  const original = globalThis.fetch;
  globalThis.fetch = ((input: string | URL | Request) => {
    const url = new URL(String(input));
    if (url.hostname === 'auth.test') return Promise.resolve(Response.json({ id: 'user' }));
    check(!url.searchParams.has('key'), 'Wyzie key leaked to fallback');
    return Promise.resolve(new Response(new Uint8Array(zipSync({ 'captions.srt': strToU8('1\n00:00:01,000 --> 00:00:03,000\nHello\n') })).buffer));
  }) as typeof fetch;
  try {
    const result = await handleRequest(request(`action=download&url=${encodeURIComponent('https://www.opensubtitles.org/en/subtitleserve/sub/123')}`));
    check(result.status === 200 && (await result.text()).includes('Hello'), 'ZIP captions missing');
  } finally { globalThis.fetch = original; }
});

Deno.test('requires user authentication', async () => {
  check((await handleRequest(new Request('https://local/subtitles'))).status === 401, 'Anonymous request accepted');
});

Deno.test('maps episode search and removes provider key from results', async () => {
  setup();
  const original = globalThis.fetch;
  globalThis.fetch = ((input: string | URL | Request, init?: RequestInit) => {
    const url = new URL(String(input));
    if (url.hostname === 'auth.test') return Promise.resolve(Response.json({ id: 'user' }));
    check(url.searchParams.get('id') === '123' && url.searchParams.get('season') === '2' && url.searchParams.get('episode') === '3', 'Wrong identity');
    check(url.searchParams.get('key') === 'private-test-key', 'Missing key');
    check(!new Headers(init?.headers).has('Authorization'), 'User session leaked');
    return Promise.resolve(Response.json([{ url: 'https://sub.wyzie.io/c/test/id/99?key=private-test-key&format=srt', language: 'en', format: 'srt', release: 'WEB' }]));
  }) as typeof fetch;
  try {
    const result = await handleRequest(request('action=search&type=episode&tmdb_id=123&season=2&episode=3'));
    const text = await result.text();
    check(result.status === 200 && text.includes('downloadUrl') && !text.includes('private-test-key'), 'Bad normalized response');
  } finally { globalThis.fetch = original; }
});

Deno.test('blocks arbitrary download hosts and non-subtitle paths', async () => {
  setup();
  const original = globalThis.fetch;
  let calls = 0;
  globalThis.fetch = (() => { calls++; return Promise.resolve(Response.json({ id: 'user' })); }) as typeof fetch;
  try {
    for (const url of ['https://evil.test/c/test/id/99', 'https://sub.wyzie.io/admin', 'https://sub.wyzie.io:444/c/test/id/99']) {
      check((await handleRequest(request(`action=download&url=${encodeURIComponent(url)}`))).status === 400, 'Unsafe URL accepted');
    }
    check(calls === 3, 'Unexpected upstream request');
  } finally { globalThis.fetch = original; }
});

Deno.test('downloads captions with server key and no forwarded bearer', async () => {
  setup();
  const original = globalThis.fetch;
  globalThis.fetch = ((input: string | URL | Request, init?: RequestInit) => {
    const url = new URL(String(input));
    if (url.hostname === 'auth.test') return Promise.resolve(Response.json({ id: 'user' }));
    check(url.searchParams.get('key') === 'private-test-key', 'Missing provider key');
    check(init?.redirect === 'manual', 'Redirects must not be followed automatically');
    check(!new Headers(init?.headers).has('Authorization'), 'Bearer leaked');
    return Promise.resolve(new Response('1\n00:00:01,000 --> 00:00:03,000\nHello\n'));
  }) as typeof fetch;
  try {
    const result = await handleRequest(request(`action=download&url=${encodeURIComponent('https://sub.wyzie.io/c/test/id/99')}`));
    check(result.status === 200 && (await result.text()).includes('Hello'), 'Missing captions');
  } finally { globalThis.fetch = original; }
});

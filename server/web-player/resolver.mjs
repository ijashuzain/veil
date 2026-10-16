import { chromium } from 'playwright';
import { publicTarget } from './network.mjs';

export function contentIdentity(input) {
  if (!input || !Number.isSafeInteger(input.id) || input.id <= 0 || !['movie', 'tv'].includes(input.type) || input.provider !== 'cinesrc') throw new Error('Invalid title or provider');
  if (input.type === 'tv' && (![input.season, input.episode].every(n => Number.isSafeInteger(n) && n > 0 && n < 10000))) throw new Error('Invalid episode');
  return `${input.type}:${input.id}:${input.type === 'tv' ? `${input.season}:${input.episode}` : ''}`;
}

export async function resolve(input) {
  contentIdentity(input);
  const entry = new URL(`https://cinesrc.st/embed/${input.type}/${input.id}`);
  if (input.type === 'tv') { entry.searchParams.set('s', input.season); entry.searchParams.set('e', input.episode); }
  const browser = await chromium.launch({ headless: true, chromiumSandbox: true, timeout: 15000, args: ['--disable-dev-shm-usage', '--autoplay-policy=no-user-gesture-required'] });
  const hardDeadline = setTimeout(() => browser.close().catch(() => {}), 60000);
  try {
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    await context.addInitScript(() => {
      window.open = () => null;
      document.addEventListener('play', event => { if (event.target.tagName === 'VIDEO') event.target.muted = true; }, true);
    });
    const approved = new Map();
    await context.route('**/*', async route => {
      try {
        const url = new URL(route.request().url());
        if (!['https:', 'http:'].includes(url.protocol)) return route.continue();
        if (url.protocol !== 'https:') return route.abort();
        if (!approved.has(url.origin)) approved.set(url.origin, publicTarget(url.href));
        await approved.get(url.origin);
        await route.continue();
      } catch { await route.abort().catch(() => {}); }
    });
    const page = await context.newPage();
    context.on('page', popup => { if (popup !== page) popup.close().catch(() => {}); });
    const candidates = new Map();
    page.on('response', response => {
      if (!response.ok() || (!/mpegurl/i.test(response.headers()['content-type'] || '') && !/\.m3u8(?:[?#]|$)|\/api\/playlist\//i.test(response.url()))) return;
      (async () => {
        const body = await response.text();
        if (body.length <= 4 * 1024 * 1024 && body.trimStart().startsWith('#EXTM3U')) candidates.set(response.url(), { body, headers: await response.request().allHeaders() });
      })().catch(() => {});
    });
    await page.goto(entry.href, { waitUntil: 'domcontentloaded', timeout: 20000 });
    const deadline = Date.now() + 30000;
    while (!candidates.size && Date.now() < deadline) {
      for (const frame of page.frames()) {
        await frame.evaluate(() => {
          document.querySelectorAll('video').forEach(v => { v.muted = true; v.play().catch(() => {}); });
          const play = document.querySelector('#bigPlay, .jw-icon-display, .vjs-big-play-button, button[aria-label="Play"]');
          if (play && !play.dataset.veilClicked) { play.dataset.veilClicked = '1'; play.click(); }
        }).catch(() => {});
      }
      await page.waitForTimeout(500);
    }
    const selected = [...candidates].find(([, c]) => c.body.includes('#EXT-X-STREAM-INF')) ?? [...candidates][0];
    if (!selected) throw new Error('No playable stream resolved');
    const [url, capture] = selected;
    const headers = {};
    for (const name of ['referer', 'origin', 'user-agent', 'authorization', 'cookie']) if (capture.headers[name]) headers[name] = capture.headers[name];
    const cookies = await context.cookies(url);
    if (cookies.length) headers.cookie = cookies.map(c => `${c.name}=${c.value}`).join('; ');
    return { url, headers, resolvedAt: Date.now() };
  } finally { clearTimeout(hardDeadline); await browser.close(); }
}

export class ResolverQueue {
  constructor(worker = resolve) { this.worker = worker; this.waiting = 0; this.tail = Promise.resolve(); this.cache = new Map(); }
  async get(input) {
    const key = contentIdentity(input);
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.resolvedAt < 30000) return cached;
    if (this.waiting >= 3) throw Object.assign(new Error('Player busy. Please retry shortly.'), { status: 429 });
    this.waiting++;
    const result = this.tail.then(async () => {
      const recent = this.cache.get(key);
      if (recent && Date.now() - recent.resolvedAt < 30000) return recent;
      const value = await this.worker(input);
      this.cache.set(key, value);
      if (this.cache.size > 3) this.cache.delete(this.cache.keys().next().value);
      return value;
    });
    this.tail = result.catch(() => {});
    try { return await result; } finally { this.waiting--; }
  }
}

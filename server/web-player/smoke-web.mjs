import http from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { once } from 'node:events';
import assert from 'node:assert/strict';
import { chromium } from 'playwright';

const root = path.resolve(process.argv[2]);
const server = http.createServer(async (req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  if (pathname === '/captions.vtt') { res.setHeader('Content-Type', 'text/vtt'); res.end('WEBVTT\n\n00:00:00.000 --> 00:01:00.000\n<i>Small web captions</i>\n'); return; }
  const file = path.resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
  if (!file.startsWith(root + path.sep)) { res.writeHead(403); res.end(); return; }
  try {
    const type = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json' }[path.extname(file)];
    if (type) res.setHeader('Content-Type', type);
    res.end(await readFile(file));
  } catch { res.writeHead(404); res.end(); }
});
server.listen(0, '127.0.0.1'); await once(server, 'listening');
let browser;
try {
  browser = await chromium.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true });
  const page = await browser.newPage({ viewport: { width: 1200, height: 700 } });
  page.on('pageerror', error => console.log('Browser error:', error.message.slice(0, 200)));
  await page.goto(`http://127.0.0.1:${server.address().port}`);
  const accessibility = page.getByRole('button', { name: 'Enable accessibility' });
  await accessibility.waitFor({ state: 'attached', timeout: 20000 });
  await accessibility.evaluate(element => element.click());
  const video = page.locator('video');
  await video.waitFor({ state: 'attached', timeout: 30000 });
  await page.waitForFunction(() => document.querySelector('video')?.readyState >= 2, null, { timeout: 30000 });
  if (await video.evaluate(v => v.paused)) await page.getByRole('button', { name: 'Play', exact: true }).click();
  await page.waitForFunction(() => document.querySelector('video').currentTime > 3, null, { timeout: 15000 });
  console.log('PASS custom web video initialization and playback');
  // Show controls before their auto-hide timer expires.
  await page.mouse.click(600, 250);
  const fit = page.getByRole('button', { name: 'Video sizing' });
  if (!await fit.isVisible()) await page.mouse.click(600, 250);
  await fit.click();
  console.log('PASS sizing control clickable');
  if (process.argv[3]) await page.screenshot({ path: process.argv[3] });
  const volumeBeforeMute = await video.evaluate(v => v.volume);
  await page.getByRole('button', { name: 'Mute', exact: true }).click();
  assert.equal(await video.evaluate(v => v.muted && v.volume === 0), true);
  await page.getByRole('button', { name: 'Unmute', exact: true }).click();
  assert.equal(await video.evaluate(v => v.muted), false);
  assert.equal(await video.evaluate(v => v.volume), volumeBeforeMute);
  console.log('PASS mute/unmute restores volume');
  await page.getByRole('button', { name: 'Enter fullscreen', exact: true }).click();
  await page.waitForFunction(() => document.fullscreenElement !== null);
  await page.getByRole('button', { name: 'Exit fullscreen', exact: true }).click();
  await page.waitForFunction(() => document.fullscreenElement === null);
  await page.getByRole('button', { name: 'Enter fullscreen', exact: true }).click();
  await page.evaluate(() => document.exitFullscreen());
  await page.getByRole('button', { name: 'Enter fullscreen', exact: true }).waitFor();
  console.log('PASS browser fullscreen entry, exit and external-exit synchronization');
  await page.getByRole('button', { name: 'Subtitles', exact: true }).click();
  await page.getByRole('button', { name: /English \(1\)/ }).click();
  await page.getByRole('button', { name: /English · provider/ }).click();
  await page.getByText('Small web captions', { exact: true }).waitFor({ timeout: 10000 });
  assert.equal(await page.getByText('<i>Small web captions</i>', { exact: true }).count(), 0);
  console.log('PASS subtitle language grouping and tag-free captions');
  await video.evaluate(v => { v.currentTime = 45; });
  await page.waitForFunction(() => { const v = document.querySelector('video'); return !v.seeking && v.currentTime > 46; }, null, { timeout: 20000 });
  console.log('PASS seek and resume');
} finally {
  await browser?.close(); server.closeAllConnections(); await new Promise(resolve => server.close(resolve));
}

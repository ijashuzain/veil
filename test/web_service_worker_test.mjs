import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

const source = await readFile(new URL('../web/veil_service_worker.js', import.meta.url), 'utf8');
function worker({ offline = false } = {}) {
  const handlers = new Map();
  const stale = new Response('old font');
  const calls = [];
  const context = vm.createContext({ URL, Response,
    self: { location: { origin: 'https://veil.vexellab.com' }, addEventListener: (name, callback) => handlers.set(name, callback) },
    caches: { open: async () => ({ match: async () => stale, put: async () => {} }) },
    fetch: async (request, options) => {
      calls.push(options);
      if (offline) throw new Error('offline');
      return new Response('current font');
    },
  });
  vm.runInContext(source, context);
  return { handlers, calls };
}

for (const file of ['/assets/fonts/MaterialIcons-Regular.otf', '/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf', '/assets/FontManifest.json', '/assets/AssetManifest.bin.json']) {
  test(`${file} uses fresh network data, not stale cache`, async () => {
    const { handlers, calls } = worker();
    let result;
    handlers.get('fetch')({ request: new Request(`https://veil.vexellab.com${file}`), respondWith: promise => { result = promise; } });
    assert.equal(await (await result).text(), 'current font');
    assert.equal(calls[0].cache, 'no-cache');
  });
}
test('offline font fetch retains cache fallback', async () => {
  const { handlers } = worker({ offline: true });
  let result;
  handlers.get('fetch')({ request: new Request('https://veil.vexellab.com/assets/fonts/MaterialIcons-Regular.otf'), respondWith: promise => { result = promise; } });
  assert.equal(await (await result).text(), 'old font');
});

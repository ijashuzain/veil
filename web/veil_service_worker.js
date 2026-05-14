'use strict';

const CACHE_NAME = 'veil-pwa-v20260509-viewport';
const APP_SHELL = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((key) => key !== CACHE_NAME)
            .map((key) => caches.delete(key)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    event.respondWith(networkFirst(request, '/index.html'));
    return;
  }

  if (isAppShellUrl(url)) {
    event.respondWith(networkFirst(request));
    return;
  }

  if (isStaticAssetUrl(url)) {
    event.respondWith(staleWhileRevalidate(request));
  }
});

function isAppShellUrl(url) {
  return [
    '/index.html',
    '/manifest.json',
    '/flutter_bootstrap.js',
    '/main.dart.js',
    '/version.json',
    '/veil_service_worker.js',
  ].includes(url.pathname);
}

function isStaticAssetUrl(url) {
  return (
    url.pathname === '/favicon.png' ||
    url.pathname.startsWith('/assets/') ||
    url.pathname.startsWith('/canvaskit/') ||
    url.pathname.startsWith('/icons/')
  );
}

async function networkFirst(request, fallbackUrl) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const response = await fetch(request);
    if (response && response.ok) {
      await cache.put(request, response.clone());
      if (fallbackUrl) {
        await cache.put(fallbackUrl, response.clone());
      }
    }
    return response;
  } catch (error) {
    return (
      (await cache.match(request)) ||
      (fallbackUrl ? await cache.match(fallbackUrl) : undefined) ||
      Response.error()
    );
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(CACHE_NAME);
  const cachedResponse = await cache.match(request);
  const fetchPromise = fetch(request).then((response) => {
    if (response && response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  });

  return cachedResponse || fetchPromise;
}

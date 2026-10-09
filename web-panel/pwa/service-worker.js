// Generated with a content-derived cache version. Only this app's static shell is cached.
const CACHE = 'wand-remote-shell-__CACHE_VERSION__';
const BASE = self.registration.scope;
const SHELL = new URL('index.html', BASE).href;
const FILES = __PRECACHE_FILES__.map((file) => new URL(file, BASE).href);
const STATIC = new Set(FILES);

self.addEventListener('install', (event) => {
    event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(FILES)));
});
self.addEventListener('activate', (event) => {
    event.waitUntil((async () => {
        const keys = await caches.keys();
        await Promise.all(keys.filter((key) => key.startsWith('wand-remote-shell-') && key !== CACHE).map((key) => caches.delete(key)));
        await self.clients.claim();
    })());
});
// A new worker waits until tabs close, unless the user explicitly chooses Reload.
self.addEventListener('message', (event) => {
    if (event.data?.type === 'APPLY_UPDATE') self.skipWaiting();
});
self.addEventListener('fetch', (event) => {
    const request = event.request;
    if (request.method !== 'GET') return;
    const url = new URL(request.url);
    const base = new URL(BASE);
    if (url.origin !== base.origin) return;
    if (request.mode === 'navigate' && (url.pathname === base.pathname || url.href.split('?')[0] === SHELL)) {
        event.respondWith((async () => {
            const controller = new AbortController();
            const timeout = setTimeout(() => controller.abort(), 4000);
            try { return await fetch(request, { signal: controller.signal }); }
            catch {
                const cache = await caches.open(CACHE);
                return await cache.match(SHELL) || new Response('Wand Remote is offline. Reconnect to your PC.', { status: 503, headers: { 'Content-Type': 'text/plain' } });
            } finally { clearTimeout(timeout); }
        })());
    } else if (STATIC.has(url.href) && url.href !== SHELL) {
        event.respondWith((async () => {
            const cache = await caches.open(CACHE);
            return await cache.match(request.url) || fetch(request);
        })());
    }
});

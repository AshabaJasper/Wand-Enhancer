// @vitest-environment node
import fs from 'node:fs';
import vm from 'node:vm';
import { describe, expect, it, vi } from 'vitest';

function worker() {
    const listeners: Record<string, (event: any) => void> = {};
    const shell = new Response('offline shell');
    const cache = { addAll: vi.fn(), put: vi.fn(), match: vi.fn(async () => shell) };
    const network = vi.fn(async () => {
        throw new Error('offline');
    });
    const skipWaiting = vi.fn();
    const source = fs
        .readFileSync(new URL('../../pwa/service-worker.js', import.meta.url), 'utf8')
        .replace('__CACHE_VERSION__', 'test')
        .replace('__PRECACHE_FILES__', JSON.stringify(['index.html', 'assets/app.js']));
    vm.runInNewContext(source, {
        self: {
            registration: { scope: 'https://pc.example/remote/' },
            addEventListener: (name: string, cb: (event: any) => void) => {
                listeners[name] = cb;
            },
            skipWaiting,
            clients: { claim: vi.fn() },
        },
        caches: { open: async () => cache, keys: async () => [], delete: vi.fn() },
        fetch: network,
        URL,
        Response,
        AbortController,
        setTimeout,
        clearTimeout,
    });
    return { listeners, cache, network, shell, skipWaiting };
}

describe('PWA cache boundaries', () => {
    it('never handles API requests, commands, external artwork or unknown files', () => {
        const { listeners } = worker();
        for (const [url, method] of [
            ['https://pc.example/remote/api/health', 'GET'],
            ['https://pc.example/remote/ws', 'GET'],
            ['https://pc.example/remote/index.html', 'POST'],
            ['https://external.example/art.png', 'GET'],
            ['https://pc.example/remote/unknown', 'GET'],
        ]) {
            const respondWith = vi.fn();
            listeners.fetch({ request: { url, method, mode: 'cors' }, respondWith });
            expect(respondWith).not.toHaveBeenCalled();
        }
    });
    it('opens only the cached shell when navigation is offline', async () => {
        const { listeners, shell, cache } = worker();
        const respondWith = vi.fn();
        listeners.fetch({
            request: {
                url: 'https://pc.example/remote/?ws=private',
                method: 'GET',
                mode: 'navigate',
            },
            respondWith,
        });
        expect(await respondWith.mock.calls[0][0]).toBe(shell);
        expect(cache.match).toHaveBeenCalledWith('https://pc.example/remote/index.html');
        expect(cache.put).not.toHaveBeenCalled();
    });
    it('does not silently activate an update during a game', () => {
        const { listeners, skipWaiting } = worker();
        listeners.message({ data: { type: 'UNRELATED' } });
        expect(skipWaiting).not.toHaveBeenCalled();
        listeners.message({ data: { type: 'APPLY_UPDATE' } });
        expect(skipWaiting).toHaveBeenCalledOnce();
    });
});

// Browser installation events are captured before asynchronous locale loading.
type InstallEvent = Event & {
    prompt(): Promise<void>;
    userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
};
export type PwaState = {
    secure: boolean;
    supported: boolean;
    installed: boolean;
    canInstall: boolean;
    pending: boolean;
    offlineReady: boolean;
    updateReady: boolean;
    failed: boolean;
};
const standalone = () =>
    Boolean(window.matchMedia?.('(display-mode: standalone)').matches) ||
    Boolean((navigator as Navigator & { standalone?: boolean }).standalone);
let state: PwaState = {
    secure: Boolean(window.isSecureContext),
    supported: 'serviceWorker' in navigator,
    installed: standalone(),
    canInstall: false,
    pending: false,
    offlineReady: false,
    updateReady: false,
    failed: false,
};
const subscribers = new Set<() => void>();
let deferred: InstallEvent | null = null;
let registration: ServiceWorkerRegistration | undefined;
let started = false;
function update(patch: Partial<PwaState>) {
    state = { ...state, ...patch };
    for (const listener of subscribers) listener();
}
export const getPwaState = () => state;
export const subscribePwa = (listener: () => void) => {
    subscribers.add(listener);
    return () => {
        subscribers.delete(listener);
    };
};
export function startPwa() {
    if (started) return;
    started = true;
    window.addEventListener('beforeinstallprompt', (event) => {
        event.preventDefault();
        deferred = event as InstallEvent;
        update({ canInstall: true });
    });
    window.addEventListener('appinstalled', () => {
        deferred = null;
        update({ installed: true, canInstall: false, pending: false });
    });
    if (!state.secure || !state.supported || import.meta.env.DEV) return;
    const base = new URL('.', window.location.href);
    navigator.serviceWorker
        .register(new URL('sw.js', base), { scope: base.pathname, updateViaCache: 'none' })
        .then((result) => {
            registration = result;
            update({ updateReady: Boolean(result.waiting && navigator.serviceWorker.controller) });
            result.addEventListener('updatefound', () => {
                const installing = result.installing;
                installing?.addEventListener('statechange', () => {
                    if (installing.state === 'installed')
                        update({
                            offlineReady: true,
                            updateReady: Boolean(
                                result.waiting && navigator.serviceWorker.controller,
                            ),
                        });
                });
            });
            navigator.serviceWorker.ready.then(() =>
                update({
                    offlineReady: true,
                    updateReady: Boolean(result.waiting && navigator.serviceWorker.controller),
                }),
            );
        })
        .catch(() => update({ failed: true }));
}
export async function installPwa() {
    if (!deferred || state.pending) return;
    const prompt = deferred;
    update({ pending: true, failed: false });
    try {
        await prompt.prompt();
        await prompt.userChoice;
    } catch {
        update({ failed: true });
    } finally {
        deferred = null;
        update({ canInstall: false, pending: false });
    }
}
export function applyPwaUpdate() {
    if (!registration?.waiting || state.pending) return;
    update({ pending: true });
    navigator.serviceWorker.addEventListener('controllerchange', () => window.location.reload(), {
        once: true,
    });
    registration.waiting.postMessage({ type: 'APPLY_UPDATE' });
}

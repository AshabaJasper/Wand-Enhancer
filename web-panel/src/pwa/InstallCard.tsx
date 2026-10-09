import { Trans } from '@lingui/react/macro';
import { useEffect, useState } from 'react';
import { applyPwaUpdate, getPwaState, installPwa, subscribePwa } from './pwa';

export function InstallCard() {
    const [state, setState] = useState(getPwaState);
    useEffect(() => subscribePwa(() => setState(getPwaState())), []);
    return (
        <section
            className="mt-5 rounded-xl border border-white/10 bg-white/5 p-4"
            aria-labelledby="install-heading"
        >
            <h3 id="install-heading" className="text-base font-semibold">
                <Trans>Keep Wand on your home screen</Trans>
            </h3>
            <div className="mt-2 space-y-2 text-sm leading-6 text-(--deck-fg-2)">
                {!state.secure ? (
                    <p>
                        <Trans>
                            Phone installation needs a private HTTPS address. This HTTP address
                            still works in your browser. HTTPS setup is a separate step.
                        </Trans>
                    </p>
                ) : state.installed ? (
                    <p role="status">
                        <Trans>Wand Remote is installed.</Trans>
                    </p>
                ) : (
                    <p>
                        <Trans>
                            Android: use Install below, or your browser menu → Install app. iPhone:
                            open in Safari, then Share → Add to Home Screen.
                        </Trans>
                    </p>
                )}
                <p>
                    <Trans>
                        Wand and your PC must stay on for game controls. Offline mode opens the
                        interface only; it cannot control a disconnected game.
                    </Trans>
                </p>
                {state.offlineReady ? (
                    <p role="status">
                        <Trans>Offline interface ready.</Trans>
                    </p>
                ) : null}
            </div>
            {state.canInstall && !state.installed ? (
                <button
                    type="button"
                    disabled={state.pending}
                    onClick={() => void installPwa()}
                    className="mt-3 min-h-12 w-full rounded-xl bg-(--deck-accent) px-4 font-semibold text-black disabled:opacity-60"
                >
                    <Trans>Install Wand Remote</Trans>
                </button>
            ) : null}
            {state.updateReady ? (
                <div className="mt-3">
                    <p role="status" className="mb-2 text-sm">
                        <Trans>
                            A panel update is ready. Reload when you are done using the controls.
                        </Trans>
                    </p>
                    <button
                        type="button"
                        disabled={state.pending}
                        onClick={applyPwaUpdate}
                        className="min-h-12 w-full rounded-xl border border-white/20 px-4 font-semibold"
                    >
                        <Trans>Reload updated panel</Trans>
                    </button>
                </div>
            ) : null}
            {state.failed ? (
                <p role="alert" className="mt-3 text-sm text-red-200">
                    <Trans>
                        Installation setup did not finish. Check your connection and reload this
                        page to retry.
                    </Trans>
                </p>
            ) : null}
        </section>
    );
}

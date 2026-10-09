import { msg } from '@lingui/core/macro';
import { useLingui } from '@lingui/react';
import { EConnectionStatus } from '@/remote-session/remote-session.reducer';
import { Icon } from '@/shared/ui/Icon';

type FloatingDockProps = {
    status: EConnectionStatus;
    runningGameTitle: string | null;
    hidden: boolean;
    leftHasBadge: boolean;
    rightHasBadge: boolean;
    onOpenSettings: () => void;
    onOpenLibrary: () => void;
};

// Keep primary navigation reachable while scrolling and above phone safe areas.
export const FloatingDock = ({
    status,
    runningGameTitle,
    onOpenSettings,
    onOpenLibrary,
}: FloatingDockProps) => {
    const { _ } = useLingui();
    const connected = status === EConnectionStatus.Connected;
    return (
        <nav
            aria-label={_(msg`Remote navigation`)}
            className="absolute inset-x-0 bottom-0 z-20 border-t border-white/10 bg-[#10131a] px-3 pt-2 pb-[max(10px,env(safe-area-inset-bottom))]"
        >
            <div className="mx-auto flex max-w-3xl items-center gap-3">
                <button
                    type="button"
                    className="flex min-h-12 shrink-0 items-center gap-2 rounded-xl px-3 text-sm font-semibold text-(--deck-fg-2) hover:bg-white/5"
                    onClick={onOpenSettings}
                >
                    <Icon className="size-5" name="settings" />
                    {_(msg`Settings`)}
                </button>
                <span className="min-w-0 flex-1 truncate text-center text-xs text-(--deck-fg-2)">
                    {runningGameTitle || _(connected ? msg`PC connected` : msg`PC offline`)}
                </span>
                <button
                    type="button"
                    className="flex min-h-12 shrink-0 items-center gap-2 rounded-xl bg-(--deck-accent) px-4 text-sm font-semibold text-black"
                    onClick={onOpenLibrary}
                >
                    <Icon className="size-5" name="list" />
                    {_(msg`Library`)}
                </button>
            </div>
        </nav>
    );
};

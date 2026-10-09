import { msg } from '@lingui/core/macro';
import { useLingui } from '@lingui/react';

import type { TrainerSummary } from '../../../protocol/messages';
import { PlaceholderState } from './PlaceholderState';

type SessionPlaceholderProps = {
    connected: boolean;
    activeTrainer: TrainerSummary | null;
    onOpenLibrary: () => void;
    onOpenSettings: () => void;
};

export const SessionPlaceholder = ({
    connected,
    activeTrainer,
    onOpenLibrary,
    onOpenSettings,
}: SessionPlaceholderProps) => {
    const { _ } = useLingui();

    if (!connected) {
        return (
            <PlaceholderState
                icon="plug"
                title={_(msg`Connect to your PC`)}
                sub={_(
                    msg`Keep Wand open on your PC and use the same Wi-Fi. After a Wand update, reapply Enhancer on the PC, then reconnect here.`,
                )}
                action={_(msg`Open Settings`)}
                onAction={onOpenSettings}
            />
        );
    }

    if (!activeTrainer) {
        return (
            <PlaceholderState
                icon="gamepad-variant-outline"
                title={_(msg`Select a game`)}
                sub={_(
                    msg`Your PC is connected. Choose a game from your library. For RDR2, load Story Mode before starting its trainer.`,
                )}
                action={_(msg`Browse library`)}
                onAction={onOpenLibrary}
            />
        );
    }

    return null;
};

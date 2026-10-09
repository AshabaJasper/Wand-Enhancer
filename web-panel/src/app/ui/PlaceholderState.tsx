import { Icon, type IconName } from '@/shared/ui/Icon';

type PlaceholderStateProps = {
    icon: IconName;
    title: string;
    sub: string;
    action: string;
    onAction: () => void;
};

export const PlaceholderState = ({ icon, title, sub, action, onAction }: PlaceholderStateProps) => {
    return (
        <div className="mx-auto flex min-h-[min(58dvh,440px)] max-w-lg flex-col items-center justify-center px-4 py-8 text-center sm:py-14">
            <div className="mb-5 flex size-16 items-center justify-center rounded-2xl bg-white/5 text-(--deck-accent)">
                <Icon className="size-7" name={icon} stroke={1.6} />
            </div>
            <h2 className="text-2xl font-semibold text-(--deck-fg)">{title}</h2>
            <p className="mt-3 max-w-80 text-base leading-7 text-(--deck-fg-2)">{sub}</p>
            <button
                type="button"
                className="mt-6 inline-flex min-h-12 w-full max-w-72 items-center justify-center gap-3 rounded-xl bg-(--deck-accent) px-5 py-3 text-base font-semibold text-black"
                onClick={onAction}
            >
                {action}
                <Icon className="size-3.5" name="arrow-right" stroke={2.2} />
            </button>
        </div>
    );
};

# 🚀 Quick start: first session

[← Back to the README](../README.md) · [Phone play](PHONE-PLAY.md) · [Respawn guide](RESPAWN-GUIDE.md)

This is the setup path I use for this fork. Start with the desktop, confirm your game works, then add phone controls.

## 1. Grab your gear

- A Windows account with Wand installed and signed in.
- Enhancer **2.1.5**, extracted with its `build-info.json` file.
- A game detected by Wand that you can test yourself.

Get the build from the [download link in the README](../README.md#get-in-game). The checked combination is Enhancer **2.1.5 + Wand 12.66.0**. This does not confirm compatibility with every game or newer Wand version.

## 2. Clear the setup screen

Save and close your game. Let Wand finish any update, then exit Wand and its tray icon. Open `WandEnhancer.exe` from File Explorer in the Windows account where you play.

Check the detected version and folder. A normal per-user installation looks like:

```text
%LOCALAPPDATA%\Wand\app-<version>
```

Use **Rescan** if Wand was just installed or updated. Use **Browse…** only when you know the correct installation folder. Do not select another Windows account's installation.

## 3. Choose your loadout

Open **Choose changes…** and review the options.

| Option | My starting point |
| --- | --- |
| Strategy | **Static**, the setup checked on my main account. |
| Remote Web Panel | Enable it if you want phone controls. |
| Auto-apply after updates | Optional. Enable it only if you want the background watcher and Windows sign-in startup. |
| Custom scripts | Leave these empty unless you understand the scripts you are adding. |

Apply once and let it finish. The success state should read:

> **Changes applied**
>
> **Support files verified. Original backup available.**

Keep the backups. If you see an error instead, use the [respawn guide](RESPAWN-GUIDE.md) before trying again.

## 4. First-session checklist

These are checks for you to perform, not a claim that they have already passed on your PC.

- [ ] Wand opens and shows the expected game.
- [ ] The game starts from Wand.
- [ ] The trainer connects to that game.
- [ ] One selected control behaves as expected.
- [ ] Stopping the trainer and closing the game returns the UI to idle.
- [ ] If enabled, the phone panel connects and shows the same active game.

My own game/trainer test is still pending. The [verification record](upstream-sync-2026-10-25.md#verification-and-limits) separates completed installation checks from gameplay.

## Another Windows account

Your **Windows account** decides which local Wand installation gets patched. Your **Wand login** is the account inside the app. Signing into the same Wand login on two Windows accounts does not share the patch.

1. Sign into the Windows account where you play, such as **Gaming**.
2. Install official Wand there if needed, open it and sign in privately.
3. Bring over only `WandEnhancer.exe` and `build-info.json`. Keep them together in a folder that account can access.
4. Follow steps 2 and 3 above. Confirm the installation folder belongs to this Windows account.
5. Close Wand in the other Windows session before using the remote panel. Two sessions can compete for port `3223`.
6. Run your first-session checklist in this account too.

Do not copy another account's Wand profile, cookies or login data. There is no need to move games or saves for this patch; Wand still needs the correct game location and that Windows account needs access to it.

> [!IMPORTANT]
> The shared **Wand Gaming Setup 2.1.3** kit and its `START-HERE.cmd` are legacy tools for Wand **12.63.0 only**. They intentionally reject 12.66.0. Do not edit out that check. The Gaming account still needs its own current setup and verification.

## Ready for the couch?

Continue with [phone play](PHONE-PLAY.md). If something gets stuck, open the [respawn guide](RESPAWN-GUIDE.md).

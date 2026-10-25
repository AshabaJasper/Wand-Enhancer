# 🛠 Respawn guide: get back to your session

[← Back to the README](../README.md) · [Quick start](QUICK-START.md) · [Phone play](PHONE-PLAY.md)

Something stuck? Start with the message you can see. Keep your original backups and the exact error so a retry does not turn into guesswork.

## Find your checkpoint

| What you see | Next move |
| --- | --- |
| **Executable is still locked** or **file is being used by another process** | Let Wand's updater finish. Close the game, Wand and its tray icon, then retry once. If it persists, export logs. |
| **Recovery needed** | Close the game and Wand. Preserve backups, then retry or use **Restore** on that same installation. |
| **Support files missing/incomplete** | Keep backups and repair the official Wand installation in that Windows account before retrying. |
| **Another operation is running** | Wait for the active patch or restore to finish. Run one enhancer operation at a time. |
| No installation detected | Confirm Wand is installed in the current Windows account, then use **Rescan**. |
| Game appears but will not start | Use the game-start checks below. Library detection alone does not prove trainer compatibility. |
| Legacy Gaming wizard rejects the version | Use the [current setup guide](QUICK-START.md#another-windows-account). The old kit is limited to 12.63.0. |

## Game appears but will not start

1. Note the Wand version, enhancer version/build, game name and game store or launcher.
2. Check whether the game opens normally from its own launcher. This helps separate a game-install problem from a Wand/trainer problem.
3. Record what happens in Wand: no response, an error, game starts without trainer, or loading never finishes.
4. Export the enhancer logs and include the exact message. Use the report template below.

The checked installation is **Enhancer 2.1.5 with Wand 12.66.0**. My real game/trainer test is still pending. Repeatedly applying a patch is not proof that a particular game is supported.

## Phone will not connect

1. Keep patched Wand open on the PC with **Remote Web Panel** enabled.
2. Check that phone and PC use the same trusted network. Avoid guest Wi-Fi that isolates devices.
3. Use the PC's current LAN address, not `localhost` or an old address from another router.
4. Check whether a phone VPN or the relevant firewall rule is blocking local access. The optional [Phone Helper](../PhoneHelper/README.md) can check the address and request a scoped rule.
5. Close Wand in other Windows sessions if they are competing for port `3223`.

Do not turn off the firewall or expose the port publicly. A healthy endpoint on the PC does not prove the phone can reach it.

## Wand updated. Now what?

**Auto-apply enabled:** the background watcher waits for the updater to exit and the new archive to settle, then attempts your saved selection. Check the enhancer's status afterward. A future incompatible version can still need a code update.

**Auto-apply disabled:** let the update finish, close Wand, open the enhancer and use **Rescan**. Check compatibility before applying again.

Auto-apply does not download a new enhancer for you. GitHub release notifications, available only in optional builds, are a separate feature.

## Undo the patch

1. Save and close the game. Exit Wand and its tray icon.
2. Open the enhancer and select the same installation you patched.
3. Choose **Restore** and wait for it to finish. Restore also stops the update watcher.
4. Open Wand and check the result.

Do not delete backups to force a fresh start. If Restore fails, retain the logs and original files before making more changes.

## Send a useful bug report

Use **Export logs to file** in the enhancer. Keep `launcher.log` and `launcher.prev.log` if they are present. Review logs and screenshots before sharing: remove private paths, account details, tokens and other personal information. Never post passwords, verification codes or Wand profile storage.

Copy this into a report for this fork:

```text
Wand version:
Enhancer version and build:
Windows account context: main account / separate gaming account
Patch strategy and selected options:
Game and store/launcher, if relevant:

What I tried:
1.
2.

What I expected:
What actually happened:
Exact error message:
Does the game open from its own launcher?
Does the problem happen every time?
Redacted logs/screenshots:
```

[Open this fork's issue tracker](https://github.com/AshabaJasper/Wand-Enhancer/issues) · [Detailed verification notes](upstream-sync-2026-10-25.md#verification-and-limits)

# Wand Enhancer — AshabaJasper's edition

A Windows companion for Wand (formerly WeMod), with a clearer desktop interface, safer recovery and a phone-friendly remote panel. Based on [k1tbyte/Wand-Enhancer](https://github.com/k1tbyte/Wand-Enhancer). This is an unofficial community project.

**Your fork's `master` includes the original project's updates through [d6cbb7b](https://github.com/k1tbyte/Wand-Enhancer/commit/d6cbb7b6912d3f4c74700106ac2dc7426f9616c2), plus the personal UI and repair improvements.**

## Download

**[Download Enhancer 2.1.5 from the build page](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/40147175184)**

1. Sign into GitHub and open the link above.
2. Scroll to **Artifacts** and download **WandEnhancer-unsigned**.
3. Extract the ZIP. Keep `WandEnhancer.exe` and `build-info.json` together.
4. Open `WandEnhancer.exe` from Windows File Explorer.

The executable is unsigned. Its manifest identifies the source commit and SHA-256. Use this repository's artifact; do not remove verification checks or disable antivirus protection to run a different download.

| Version | Verification |
| --- | --- |
| **2.1.5 — current build, tested on the actual PC** | Applied to Wand **12.66.0** on 25 October 2026. Both apps reopened and responded; backup status, remote health, running watcher and Windows sign-in registration passed. [Build](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/40147175184) · [Evidence and limits](docs/upstream-sync-2026-10-25.md#verification-and-limits). |
| **2.1.4 — previous repair** | Wand **12.66.0** patching, reapplying while running, startup and remote connectivity passed. [Build](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/40146135380) · [Evidence](docs/wand-12.66-file-lock-repair.md). |

A build or connected remote panel does not prove that a trainer works in a game. Gameplay testing remains separate. Newer Wand versions need fresh compatibility checks.

## Set up Wand

1. Sign into the **Windows account where you play**. Install [official Wand](https://wand.com/download), open it and sign in privately.
2. Save and close your game. Let any Wand update finish, then exit Wand and its tray icon.
3. Open the enhancer. Confirm the detected installation belongs to this Windows account: `%LOCALAPPDATA%\Wand\app-<version>`. Use **Rescan** or **Browse…** if needed.
4. Choose **Choose changes…**. Use **Static** for the configuration tested on this PC, and select **Remote Web Panel** if you want phone controls.
5. Apply. Wait for **Changes applied** and **Support files verified. Original backup available.**
6. Open Wand and test your game.

**Keep the original backups.** Only run one patch or restore at a time. If setup reports an unsupported version or incomplete files, stop and retain the error.

### Using the separate Gaming Windows account

The Windows account and the Wand login are different. Signing into the same Wand account does not transfer the patch.

- Sign into **Gaming** and repeat the setup above there. Confirm the selected folder belongs to Gaming.
- Share only the enhancer executable and build manifest. Do not copy another Windows account's Wand profile, cookies or login data.
- Close Wand in the other Windows session before using the phone panel; both sessions would compete for port `3223`.
- Games and saves stay in place. Gaming still needs access to the game folder and correct game detection in Wand.

**The older `START-HERE.cmd` Gaming kit is for Wand 12.63.0 only.** It is not the current installer and intentionally rejects 12.66.0. Use the steps above for the current version. [Legacy kit details](scripts/windows-gaming-setup/README.md). Gaming's installation and gameplay require their own verification.

## Use your phone

1. Keep patched Wand open on the PC.
2. Connect the phone and PC to the **same trusted local network**.
3. Use **Connect** in Wand, or open `http://YOUR-PC-LAN-IP:3223/remote/` on the phone.
4. Wait for **Connected**, then open **Library**.

The optional [Phone Helper](PhoneHelper/README.md) shows the LAN address, a QR code and connection checks. Install it separately in each Windows account that needs it.

The remote panel has no pairing authentication. Anyone who can reach its port can control the active trainer. Do not forward port `3223` to the internet. Phone home-screen installation requires trusted HTTPS; ordinary LAN HTTP works as a browser controller. Offline mode caches only the interface, not live game controls.

## Updates and recovery

**Auto-apply after updates is optional.** In 2.1.5, applying with this enabled installs a background watcher that starts at Windows sign-in. It waits for the updater to exit and the new archive to settle, then attempts your saved selection. Apply again with the option off, or choose **Restore**, to stop it. The checkbox's tooltip and screen-reader help explain this behavior. A future incompatible Wand update can still require manual repair.

Without auto-apply, let Wand finish updating, close it, open the enhancer, choose **Rescan** and apply again after checking compatibility.

| What you see | What to do |
| --- | --- |
| **Recovery needed** | Close games and Wand. Keep backups, then retry or choose **Restore**. |
| **Executable is still locked** | Let the updater finish. Close Wand and games using its overlay, then retry. |
| **Support files missing/incomplete** | Preserve the backups and repair official Wand in that Windows account. |
| **Another operation is running** | Wait for it to finish. Do not launch another patcher. |
| Phone will not connect | Check the PC's current LAN address, shared network and firewall rule. |
| You want to undo the patch | Close games and Wand, select the same installation in the enhancer, then choose **Restore**. |

For help, use **Export logs** and include Wand version, enhancer version/build, Windows account context and the exact error. Keep `launcher.log` and `launcher.prev.log`; remove personal details before sharing. Never include passwords or verification codes.

## What this fork keeps

- Desktop version/build identity, **Rescan**, support-file health and recovery guidance.
- Phone navigation, accessible controls, home-screen guidance and the optional Phone Helper.
- Original-file validation, transactional backup replacement and rollback protections.
- Installation-scoped helper shutdown and executable-lock retries.
- Upstream's auxiliary-service compatibility fixes, optional update watcher and Bengali locale.

See the [changelog](CHANGELOG.md), [upstream sync notes](docs/upstream-sync-2026-10-25.md) and [UI acceptance notes](docs/ui-acceptance.md).

## Build from source

Use this fork's **master** branch. On Windows, install Node.js, pnpm and Visual Studio/Build Tools with MSBuild and .NET Framework 4.8 targeting tools, then run:

```powershell
./build.cmd
```

The build runs web lint, type checks, production-asset checks, web tests, desktop recovery tests, patch-locator tests, auxiliary checks and real-process lock/watcher fixtures. Fixtures use temporary folders, never a real Wand profile.

`build.cmd -EnableUpdateNotifications` adds optional GitHub release notifications. This is separate from the local auto-apply watcher. Default builds omit release notifications; neither option downloads an enhancer update for you. If an artifact has expired, run [Build executable](https://github.com/AshabaJasper/Wand-Enhancer/actions/workflows/build.yml) on **master**.

Custom renderer scripts have Node access inside Wand. Add only scripts you understand. [Contribution guide](CONTRIBUTING.md) · [Apache-2.0 license](LICENSE.md).

## Credits

Original project: [k1tbyte](https://github.com/k1tbyte/Wand-Enhancer). Trainer compatibility: [PR #345](https://github.com/k1tbyte/Wand-Enhancer/pull/345). Background watcher: [PR #318](https://github.com/k1tbyte/Wand-Enhancer/pull/318). Scoped shutdown was adapted from [PR #359](https://github.com/k1tbyte/Wand-Enhancer/pull/359), with this fork's additional installer and backup safeguards.

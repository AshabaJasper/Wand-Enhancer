# 🎮 Wand Enhancer | Jasper's Edition

**My Wand setup, with a cleaner desktop, phone controls and a way back when an update causes trouble.**

I'm Jasper. This is my fork of [k1tbyte's Wand Enhancer](https://github.com/k1tbyte/Wand-Enhancer). I keep the original project's updates and add the things I want in my own setup: clearer buttons, useful recovery messages and a remote panel I can use from my phone.

Credit for the original project goes to **k1tbyte** and its contributors. This is an unofficial community tool for Wand, formerly WeMod.

**[⬇ Get 2.1.5](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/40147175184)** · **[🚀 Quick start](docs/QUICK-START.md)** · **[📱 Phone play](docs/PHONE-PLAY.md)** · **[🛠 Respawn guide](docs/RESPAWN-GUIDE.md)**

## Pick your next move

| I want to... | Go here |
| --- | --- |
| Get set up and open Wand | [Quick start](docs/QUICK-START.md) |
| Use my phone as a controller | [Phone play](docs/PHONE-PLAY.md) |
| Set up a separate Gaming Windows account | [Gaming account setup](docs/QUICK-START.md#another-windows-account) |
| Fix a locked file, failed patch or connection | [Respawn guide](docs/RESPAWN-GUIDE.md) |
| See what changed | [Changelog](CHANGELOG.md) |
| Help improve this fork | [Contributing](CONTRIBUTING.md) |

## Get in game

1. **Download:** open the [2.1.5 build page](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/40147175184), sign into GitHub and find **Artifacts → WandEnhancer-unsigned**.
2. **Extract:** keep `WandEnhancer.exe` and `build-info.json` together. Open the executable from File Explorer.
3. **Prepare:** use the Windows account where you play. Install and sign into [official Wand](https://wand.com/download), let updates finish, then close your game and Wand, including its tray icon.
4. **Choose:** check the detected installation, open **Choose changes…** and use **Static** for the setup tested here. Select **Remote Web Panel** if you want phone controls.
5. **Apply:** wait for **Changes applied** and **Support files verified. Original backup available.** Open Wand and test your game.

> [!TIP]
> First time here? The [quick-start guide](docs/QUICK-START.md) explains each step, your first-session checklist and the separate Gaming account setup.

## What's in my loadout?

| Feature | What it helps with |
| --- | --- |
| Clear desktop controls | See the version, rescan your installation and find recovery actions. |
| Phone remote panel | Browse your library and use trainer controls from a browser on your local network. |
| Pins and presets | Keep favourite controls handy and save persistent trainer values per game. |
| Backup and restore | Keep the original resources available when you need to undo a patch. |
| Optional update watcher | Reapply your saved selection after Wand finishes updating. |
| Optional Phone Helper | Find your LAN link, scan a QR code and check connection problems. |

The Phone Helper is a [separate install](PhoneHelper/README.md). It is not bundled into the enhancer download.

## What I've checked so far

**Current build: 2.1.5. Tested Wand version: 12.66.0. Checked on 25 October 2026.**

| Check | Result |
| --- | --- |
| Apply 2.1.5 on my main Windows account | Passed |
| Open Wand and the enhancer after applying | Both opened and responded |
| Original backup and installation status | Verified, no installation issue reported |
| Remote health check | Healthy, two games detected |
| Background update watcher | Running, Windows sign-in entry registered |
| Gameplay and trainer controls in a real game | Still needs my hands-on test |
| Separate Gaming Windows account | Still needs its own upgrade and checks |
| A real future Wand update and next Windows sign-in | Not yet tested |

I want this table to show what actually passed. A healthy connection or a successful build does not mean every game works. New Wand versions need fresh compatibility checks. [Full verification notes](docs/upstream-sync-2026-10-25.md#verification-and-limits).

## Keep your next session simple

- **Keep the backups.** Use **Restore** to undo changes on the same installation.
- **Let updates finish.** Auto-apply is optional. When enabled and applied, its watcher runs in the background and starts at Windows sign-in. Turn it off and apply again, or use **Restore**, to stop it. It attempts your saved selection; future incompatible versions may still need a repair.
- **Use the right Windows account.** A Wand login does not transfer a local patch. The old `START-HERE.cmd` kit is version 2.1.3 and only accepts Wand 12.63.0. Follow the [current account guide](docs/QUICK-START.md#another-windows-account) instead.
- **Keep phone controls on a trusted LAN.** The panel has no pairing authentication. Anyone who can reach its port can control the active trainer. Do not expose port `3223` to the internet.

<details>
<summary><strong>🔧 Build it yourself</strong></summary>

Use this fork's **master** branch on Windows. Install Node.js, pnpm and Visual Studio or Build Tools with MSBuild and the .NET Framework 4.8 targeting tools.

```powershell
git clone https://github.com/AshabaJasper/Wand-Enhancer.git
cd Wand-Enhancer
./build.cmd
```

The build runs web checks and tests, desktop recovery checks, patch-locator checks, auxiliary checks and process-lock/watcher fixtures. Fixtures use temporary folders, not your live Wand profile.

`build.cmd -EnableUpdateNotifications` adds optional GitHub release notifications. Those notifications are separate from the local auto-apply watcher. Neither feature downloads an enhancer update for you.

If the download artifact has expired, build locally or run [Build executable](https://github.com/AshabaJasper/Wand-Enhancer/actions/workflows/build.yml) on **master** in a repository where you have Actions permissions.

Custom renderer scripts run with Node access inside Wand. Add only scripts you understand. The executable is unsigned; `build-info.json` records its source and SHA-256. Keep verification checks and antivirus protection enabled.

</details>

## Credits and patch notes

My `master` includes upstream through [d6cbb7b](https://github.com/k1tbyte/Wand-Enhancer/commit/d6cbb7b6912d3f4c74700106ac2dc7426f9616c2), with my UI and recovery changes kept on top.

Thanks to [k1tbyte and contributors](https://github.com/k1tbyte/Wand-Enhancer), including the work on [trainer compatibility #345](https://github.com/k1tbyte/Wand-Enhancer/pull/345), [background watching #318](https://github.com/k1tbyte/Wand-Enhancer/pull/318) and [scoped shutdown #359](https://github.com/k1tbyte/Wand-Enhancer/pull/359). This fork adds its own installer and backup safeguards.

[Changelog](CHANGELOG.md) · [Sync notes](docs/upstream-sync-2026-10-25.md) · [UI checks and known gaps](docs/ui-acceptance.md) · [Apache-2.0 license](LICENSE.md)

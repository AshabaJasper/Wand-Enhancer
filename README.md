# Wand Enhancer — personal edition

A Windows companion that modifies a local Wand (formerly WeMod) installation and adds a phone-friendly remote panel. This is [AshabaJasper's fork](https://github.com/AshabaJasper/Wand-Enhancer) of [k1tbyte/Wand-Enhancer](https://github.com/k1tbyte/Wand-Enhancer), not an official Wand product.

## Start here

**Latest repair: Enhancer 2.1.3.0 for Wand 12.63.0.** Use the [repair branch](https://github.com/AshabaJasper/Wand-Enhancer/tree/fix/trainer-launch-12-63) and its [successful build](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/38666405156). The default `master` source has not yet received this repair; building `master` produces the older version.

| Status | Meaning |
| --- | --- |
| Build and automated checks passed | Includes 53 web tests, desktop backup/rollback checks, JavaScript patch locations and auxiliary-service checks. |
| Applied to Wand 12.63.0 | Wand and the remote panel opened; original files remain available for Restore. |
| Game test pending | The user will test their game. An open library or connected phone does not prove that a trainer works. |
| Other Windows accounts need setup | Each account has its own Wand installation and profile. Repairing one does not repair the others. |

The repair handles newer auxiliary archive and Electron fuse checks missing from the older enhancer. [Technical evidence and limits](https://github.com/AshabaJasper/Wand-Enhancer/blob/fix/trainer-launch-12-63/docs/trainer-launch-repair.md).

## 1. Get the repaired enhancer

1. Open the [verified build run](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/38666405156).
2. Download **WandEnhancer-unsigned** under **Artifacts**. GitHub sign-in is required.
3. Extract the ZIP to a folder you will keep. Keep `WandEnhancer.exe` and `build-info.json` together.
4. Open the enhancer. This specific build shows **2.1.3.0 · 5b75213** in its header.

The manifest records version, source commit, SHA-256 and build URL. This build is unsigned; use the repository's build artifact, not executables from video descriptions or third-party mirrors.

If the artifact has expired, open [Actions → Build executable](https://github.com/AshabaJasper/Wand-Enhancer/actions/workflows/build.yml), choose **Run workflow**, select **fix/trainer-launch-12-63**, and leave update notifications off for the default offline patcher. A new build has its own manifest and commit identity.

## 2. Apply it in the account where you play

1. Sign into the correct Windows account. Save and close games, and exit Wand in any other signed-in Windows session.
2. Install or open [official Wand](https://wand.com/download) in this account and sign in privately. Then close Wand.
3. Open `WandEnhancer.exe` from File Explorer in the same account. Use **Rescan** if needed.
4. Confirm the detected folder belongs to **this account**, normally `%LOCALAPPDATA%\Wand\app-<version>`. Check the version: this repair was validated against **12.63.0**.
5. Choose **Choose changes…**, review your options, use **Static** for the tested configuration, and enable **Remote Web Panel** if you want phone controls.
6. Apply and wait for **Changes applied** and **Support files verified. Original backup available.**
7. Open Wand and test your game. For RDR2, load Story Mode before trying the trainer.

A newer Wand version is not automatically compatible. If a compatibility check fails, stop and investigate rather than bypassing it.

**Keep the backups.** Restore needs `resources/app.asar.backup`, `resources/app.asar.unpacked.backup` and the launcher/executable backups created by the enhancer. Run only one patch or restore operation at a time.

## Separate Gaming Windows account

The **Windows account** and the **Wand login** are different things. Using the same Wand login in both Windows accounts does not transfer the installed patch.

### Guided administrator setup for Gaming

On this PC, open `C:\Users\Public\Documents\Wand Gaming Setup 2.1.3` from **Gaming's File Explorer** and double-click **START-HERE.cmd**. Start it normally: the script requests administrator permission at the patch step. If Windows asks for another account's administrator credentials, enter them only in the Windows prompt; the patch target remains Gaming.

The guided sequence checks the account and file hashes, opens the official installer if Wand is missing, asks you to close Wand in all sessions, installs the repaired enhancer, verifies original resources/backups, applies the repair with administrator permission, creates Gaming's shortcuts, opens Wand as Gaming, and checks startup plus the selected remote panel. It never launches a game. You handle installer prompts, Windows approval, Wand sign-in and the final game test.

This kit accepts **Wand 12.63.0 only** and stops on another version, missing/damaged originals, custom renderer scripts or running Wand processes. An online installer may fetch a newer version; the script will stop for a compatibility check rather than patch it. Existing supported selections are kept with Static mode; a fresh setup uses Pro, F12 diagnostics and Remote Web Panel. Logs and any previous enhancer executable are saved under `%LOCALAPPDATA%\WandEnhancerSetup\runs` in Gaming. Original Wand backups stay beside the installation for **Restore**.

The [setup source and verification notes](https://github.com/AshabaJasper/Wand-Enhancer/tree/fix/trainer-launch-12-63/scripts/windows-gaming-setup) explain the pinned kit and tests. The repository scripts alone are not a complete installer kit. **Gaming's interactive setup and gameplay remain unverified until run in that account.** The optional Phone Helper remains a separate installation.

### Manual setup or another Windows account

- Transfer only the enhancer executable and build manifest through a shared folder, then copy them into a folder owned by Gaming.
- Sign into Gaming and follow the setup steps above. The detected installation should belong to Gaming, for example `C:\Users\Gaming\AppData\Local\Wand\app-12.63.0`.
- If detection points elsewhere, use **Browse…** to select Gaming's versioned Wand folder. If none exists, install official Wand while signed into Gaming first.
- Do not copy another account's Wand profile, cookies, credentials or trainer cache. Each account keeps its own settings and backups.
- Exit Wand in the other Windows session first. Two copies can compete for remote port `3223`, and the patcher stops Wand processes while applying changes.
- Use Gaming's normal File Explorer to launch setup. Packaged applications can redirect app-data paths and cause setup to target a different location.

Games on another drive may be shared, but Gaming needs access to them and Wand must detect them or be pointed to the correct executable. These steps do not move games or saves. Compatibility must be verified while signed into Gaming; success in another account is not proof.

## Phone controls

1. Keep patched Wand open in the Windows account you are using to play.
2. Connect the PC and phone to the **same trusted local network**.
3. Use **Connect** in Wand or open `http://YOUR-PC-LAN-IP:3223/remote/` on the phone. `127.0.0.1` works only on the PC.
4. Wait for **Connected**, open **Library** and select a game.

The optional [Wand Phone Helper](https://github.com/AshabaJasper/Wand-Enhancer/blob/fix/trainer-launch-12-63/PhoneHelper/README.md) provides a LAN address, QR code, connection checks and public video-guide search. Install it separately in each Windows account where you need it. Enhancer 2.1.3 includes the **Phone setup** button but does not bundle the helper installer.

The panel uses HTTP/WebSockets without pairing authentication. Anyone who can reach its port can control the active trainer. Keep it on a trusted LAN/private VPN; do not forward port `3223` to the internet or disable the firewall to connect.

### Phone home-screen installation

Open **Settings → Keep Wand on your home screen** for instructions. Full PWA installation on a phone requires trusted HTTPS. The ordinary HTTP LAN link remains a browser controller. Private HTTPS and phone installation have not been verified here.

Offline mode caches the interface only, not accounts, trainer state or commands. It cannot control games while disconnected.

## Updates, errors and Restore

After a Wand update, let it finish, close games, open the enhancer and choose **Rescan**. Check the detected version before applying. **Auto-apply after update** attempts your saved selection only while the enhancer launcher remains installed; Wand updates can replace it.

| Problem | Next step |
| --- | --- |
| Games appear, but trainers will not start | Check enhancer version/build and Windows account path. Use the repair on the validated Wand version; retain the exact error if it continues. |
| Recovery needed / unfinished operation | Close games and Wand. Keep backups, then retry or use **Restore**. |
| Support files missing or wrong size | Restore complete original files. If backups are damaged, repair/reinstall official Wand in that Windows account. |
| File replacement fails | Close the game or Wand that may hold the file open, then retry. Do not delete backups. |
| Another operation may be running | Wait for it to finish; do not start another patch or restore. |
| Phone cannot connect | Check current LAN address, network isolation and the local firewall rule. Run Wand in one Windows session. |
| You want to undo changes | Close games and Wand, open the enhancer for the same installation and choose **Restore**. |

For troubleshooting, retain `launcher.log` and `launcher.prev.log` beside Wand's launcher and use **Export logs** in the enhancer. Include Wand version, enhancer version/build, Windows account context, selected options and exact game error. Redact personal paths and account details; never include passwords or verification codes.

## Build from source

Check out **fix/trainer-launch-12-63** for this repair. Requirements: Windows, Node.js, pnpm, Visual Studio/Build Tools with MSBuild, and .NET Framework 4.8 desktop targeting tools.

```powershell
./build.cmd
```

The build lints and type-checks the panel, builds production assets, runs web tests, builds WPF, and runs desktop, patch-locator and auxiliary-compatibility tests. Fixtures use temporary directories.

`build.cmd -EnableUpdateNotifications` enables optional GitHub release notifications. Default builds exclude that code. Notifications do not download or install updates. Wand itself still uses online services.

For panel development, run `pnpm --dir web-panel install --frozen-lockfile`, then `pnpm --dir web-panel dev`. Production output excludes demo trainers. [UI acceptance and remaining limits](docs/ui-acceptance.md).

Custom renderer scripts run inside Wand with Node access. Add only scripts you understand through the patch dialog or the `renderer-scripts` folder beside the enhancer; they may execute more than once.

## Credits

Original project: [k1tbyte/Wand-Enhancer](https://github.com/k1tbyte/Wand-Enhancer). Trainer compatibility repair adapted from [RatedRCustomer's PR #345](https://github.com/k1tbyte/Wand-Enhancer/pull/345). Personal usability, recovery and phone tools are maintained in this fork. [Apache-2.0 license](LICENSE.md).

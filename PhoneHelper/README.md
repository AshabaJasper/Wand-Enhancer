# Wand Phone Helper

A companion for AshabaJasper's remote panel. This helper does not patch Wand, activate subscriptions, inject scripts or send trainer commands.

## Connect your phone

1. Open Wand and wait for its library.
2. Open **Wand Phone Helper** from Start or the desktop shortcut.
3. Choose Ethernet or Wi-Fi. **Refresh connection** detects router/IP changes.
4. Scan the QR or copy the link into your phone browser. Both devices must use the same router; Ethernet and normal Wi-Fi work together.
5. If the phone times out, check **This is my trusted home / private network**, click **Allow phone on this network** and approve Windows' administrator prompt. Refresh the phone page.

Detection probes only the loopback health endpoint and fallback ports defined by the shared web contract. It advertises active private IPv4 addresses on physical interfaces with a local gateway, excluding localhost, Docker/WSL and link-local addresses. A response on the PC does not prove phone connectivity.

The repair opens only the actual TCP panel port from LocalSubnet on the selected interface, on Private/Public profiles. It does not disable the firewall or antivirus, change the network category, forward router ports, or depend on a Wand version-specific EXE path. Conflicting helper-owned rules are reported rather than overwritten. Recheck after changing router, adapter or panel port.

Guest Wi-Fi isolation or a phone VPN may still prevent access. HTTP browser access works; phone PWA installation requires trusted HTTPS, which remains a separate setup step. The existing panel has no pairing authentication: use a trusted LAN and do not expose it publicly.

## Video guides

Enter a game title and click **Search video guides**. This opens public YouTube search results for gameplay walkthroughs. It is a search shortcut, not a built-in Wand video player, AI assistant, verified tutorial collection or paid-feature unlock. Only the title is sent, when you click.

## Install and remove

Run WandPhoneHelper-Setup.exe. Installation is per user under %LOCALAPPDATA%\Programs\WandPhoneHelper, with a Start shortcut and optional desktop shortcut. Only firewall repair requires administrator approval. Close the helper before updating.

Remove through Windows **Installed apps → Wand Phone Helper → Uninstall**. Only its named files and shortcuts are removed; extra files, Wand files/backups and firewall rules are preserved. Helper-created allowances can be reviewed in Windows Firewall under the **Wand Phone Helper** rule group. The previously repaired Ethernet rule is separate.

This personal helper is unsigned and is not an official k1tbyte release. The manifest records source revision and executable SHA-256.

## Build

On Windows with .NET Framework 4.8:

    powershell -NoProfile -File .\PhoneHelper\build.ps1

The build restores QRCoder 1.8.0 from NuGet, verifies a pinned package hash, compiles only the two helper sources with the Windows compiler, runs ten helper checks and packages a standalone installer. It does not compile or embed the Wand patcher.

Diagnostic arguments: --diagnose returns read-only JSON health output; --self-test runs local validation. Redirect stdout for these modes.

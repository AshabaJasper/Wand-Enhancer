# Guided Gaming setup

`START-HERE.cmd` starts a six-step Windows PowerShell 5.1 wizard. It must be double-clicked normally from the **Gaming** Windows account. The patch worker requests UAC automatically; the controller stays unelevated so Wand starts as Gaming, even when another administrator supplies credentials.

The local prepared kit is in `C:\Users\Public\Documents\Wand Gaming Setup 2.1.3`. Extract a distributed ZIP before opening the command file. Keep these files together:

- `START-HERE.cmd` and `Start-GamingSetup.ps1` from this directory.
- `WandEnhancer.exe` and `build-info.json` from [build 38666405156](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/38666405156), artifact `WandEnhancer-unsigned`, source commit `5b75213`.
- Official WeMod LLC-signed `Wand-Setup.exe`, SHA-256 `295B2409A5CCA6AD643CF1AAA6B29C7AB98761FDD291B15D91C41F65504A2B2B`.

The enhancer SHA-256 is `388269FB4BFE915C17657CE626E7099EF53F12F7644A44B0DE3A15AF7CC617ED`. The wizard pins these exact files. A rebuilt executable or changed official bootstrapper requires a reviewed hash update, not removing verification.

## Sequence

1. Check Gaming identity, normal desktop context and kit integrity.
2. Run the official installer if Wand is absent. The user completes its prompts.
3. Ask the user to close games and Wand in every session, then copy the enhancer into Gaming's own Programs folder, retaining the previous executable/manifest.
4. Request administrator approval. Resolve Gaming by SID/profile, confirm its desktop session, validate the complete original resources against the cached 12.63.0 package and invoke the verified patch engine. Existing original backups stay intact. No custom renderer scripts are loaded.
5. Create shortcuts and open Wand/Enhancer from the original, unelevated Gaming controller. The user signs into Wand privately.
6. Verify the running Wand path/session and, if selected, the remote health endpoint owned by that process. Record the result; leave gameplay testing to the user.

The script stops if Wand is not exactly 12.63.0, the installation is incomplete, another Wand process is active, a linked path is encountered, originals are missing/altered, UAC is cancelled or patching fails. It does not kill other users' processes, move games/saves, copy account data, change firewall rules or change the machine's execution policy. `-ExecutionPolicy Bypass` applies only to the launched PowerShell processes; organizational policy still takes precedence.

The official online installer can download a newer Wand version. The script then stops for a compatibility review. Do not delete backups or downgrade blindly to get past a check.

## Recovery and results

Logs: `%LOCALAPPDATA%\WandEnhancerSetup\runs\<run-id>` in Gaming. `admin-result.json` reports patch success/failure; `setup-result.json` reports subsequent startup/remote checks. A successful patch followed by failed startup is reported as incomplete, never as a successful setup. Cancelled UAC or failure before the worker starts may produce no administrator result.

Close games/Wand and choose **Restore** in Gaming's repaired enhancer to return original Wand files. Keep original ASAR/support backups, the stub backup and fuse backup. A prior enhancer executable/manifest, if present, is retained in the run folder. Runs never include passwords or login cookies. Review personal paths before sharing logs.

The Phone Helper is optional and installed separately; the remote panel itself is part of this setup. Game detection and trainer operation must be checked by the user.

## Verification

Run the fixture suite with Windows PowerShell 5.1:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Test-GamingSetup.ps1 -KitDirectory "C:\path\to\complete-kit"
```

24 checks passed on 15 October 2026: parser, account/elevation/AppData gates, path traversal/junction rejection, version selection, actual payload hashes and installer signature, saved selections, missing/altered/incomplete originals, complete-backup reapply, and administrator-worker target/failure/lock behavior. Fixtures are retained in a fresh temporary directory for inspection. Worker orchestration tests mock elevation, session ownership and the patch call; they never modify a real Wand installation or launch games. The real patch engine and repaired binary were validated separately against Wand 12.63.0 as documented in [the repair evidence](../../docs/trainer-launch-repair.md).

The real UAC handoff, installation and startup in **Gaming** are still pending a run from that account. Automated checks are not proof of an interactive Gaming installation or successful gameplay.

This is a local Windows setup tool, not a website. Website routing, SEO, analytics, consent, uploads and email requirements are not applicable. Relevant interface requirements are sequential progress, actionable errors, retained backups and honest success reporting.

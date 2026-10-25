# Original-master sync — 25 October 2026

This fork merges [k1tbyte/master at d6cbb7b](https://github.com/k1tbyte/Wand-Enhancer/commit/d6cbb7b6912d3f4c74700106ac2dc7426f9616c2) into AshabaJasper's existing history. Upstream is an ancestor of the resulting branch, and the personal commits remain reachable. No commits were rebased, discarded or force-pushed.

## What came from upstream

- Background update watching, started at Windows sign-in when the user applies with **Auto-apply after updates** enabled. Static launcher handling is separate from this watcher; Supervised mode still needs launcher interception.
- Shared auxiliary-signature handling for both Static and Supervised modes, including the upstream regression coverage. This fixes the root-launcher check that the earlier fork treated differently in Supervised mode.
- Bengali locale and registration.
- Updated contributor and agent guidance.

## Personal changes kept

- Desktop layout, version/build identity, **Rescan**, support-file status, recovery guidance and **Phone setup**.
- Phone panel layout, mobile navigation, accessibility, PWA assets and the standalone Phone Helper.
- Original-resource validation, incomplete-patch state, operation locking, transactional support replacement and rollback.
- Installation-scoped helper shutdown, exit waiting, bounded executable-lock retries and refusal to terminate an active installer.
- Existing personal commit history and historical repair/Gaming documentation.

The desktop and phone UI trees were compared against the previous personal master. Apart from the auto-apply checkbox's explanatory tooltip and screen-reader help, the existing desktop View files, styles, web panel and Phone Helper were unchanged by this merge.

## Integration changes

The upstream watcher originally considered an unchanged ASAR size sufficient to start patching. This fork also waits for installation-local `Update.exe` and `squirrel.exe` to exit before counting stable reads. Otherwise the watcher could attempt a patch while the updater was still working, hit our installer-protection check and miss the update.

Restore stops the watcher before changing installation files. The existing transactional restore and rollback code remains in place. Enabling auto-apply is optional; the UI help and README explain the startup behavior.

Version **2.1.5.0** distinguishes this integration from the previously installed 2.1.4 repair. See [CHANGELOG.md](../CHANGELOG.md) for the combined history.

## Verification and limits

The [integration build](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/40147175184), source `326a2d100127a2c3a77ccf2f2c5af27ff646bf67`, passed both the standard and optional-release-notification variants: all 53 web tests, backup/rollback, patch-locator, auxiliary, file-lock and watcher checks. The downloaded 2.1.5 artifact was hash-verified and its auxiliary checks also passed locally against copies of the actual Wand 12.66.0 service and client executable.

Artifact SHA-256: `3B62040D996E34BC9B6F72A6C38B34203BAB38D03C962CD72BE114466D9F35C6`.

The new watcher test starts the real watcher executable against a temporary, synthetic installation. A real sleeping updater fixture remains active while the archive size is stable: no files may be patched and the updater must not be killed. After the updater exits, the watcher must complete a Static patch, preserve its original archive backup and stay running. The stop signal must then end that watcher. The fixture never launches a game or a real Wand installation and does not register Windows startup.

This GitHub sync does not install 2.1.5 on the PC. The last real-PC verification remains [2.1.4 with Wand 12.66.0](wand-12.66-file-lock-repair.md). Game/trainer use and the separate Gaming Windows profile remain separate from build and fixture verification.

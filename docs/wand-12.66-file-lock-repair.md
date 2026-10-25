# Wand 12.66.0 executable-lock repair

Verified on 25 October 2026. Personal build **2.1.4.0**, source **08d13de187fe47be2f13eadf09ca95c2c63814e3**.

## Observed failure

Enhancer 2.1.3 reported that `app-12.66.0/Wand.exe` was being used by another process. The installation retained `.incomplete-patch` and displayed **Recovery needed**. On inspection the executable was writable again and Windows Restart Manager reported no current lock owner. The original locking process therefore cannot be identified retrospectively.

The old patcher stopped only the brand process by name and immediately attempted disk writes. A lock at the executable-enablement step occurred after resource preparation, forcing rollback and leaving the recovery marker.

## Upstream comparison

- The original project's [master at d6cbb7b](https://github.com/k1tbyte/Wand-Enhancer/commit/d6cbb7b6912d3f4c74700106ac2dc7426f9616c2) includes [PR #345](https://github.com/k1tbyte/Wand-Enhancer/pull/345), shipped in its [2.1.1.0 release](https://github.com/k1tbyte/Wand-Enhancer/releases/tag/2.1.1.0). This fork already adapted that trainer-integrity work in 2.1.3 and keeps its structural validation and rollback safeguards.
- Upstream also added auxiliary-service termination and a background update watcher. [Open PR #359](https://github.com/k1tbyte/Wand-Enhancer/pull/359), head `bf0cb9af5ce06fcfde68ae7f088557bb0d24f430`, adds installation-path process selection, exit waiting and lock diagnostics. It was still open when reviewed.
- This repair adapts the scoped shutdown and exit-wait behavior. It does not wholesale merge the open PR or add the startup watcher. In particular, it keeps this fork's transactional support-directory replacement and refuses to terminate an active updater.

## Changes

- Stop client and helper processes by executable path under the selected installation's parent folder, excluding the patcher itself. Another Windows account or sibling installation is outside that path.
- Wait for process exit. Name surviving processes/PIDs when shutdown fails.
- If `Update.exe` or `squirrel.exe` is running under the installation, stop the operation before terminating any process and ask the user to let the update finish.
- Retry executable sharing/lock violations for a bounded interval. Other I/O errors fail immediately.
- Preflight Static executable write access before creating a recovery marker or changing resources. Restore similarly checks an executable whose fuse needs restoration.
- Preserve existing feature selections, original backups and the operation lock. No antivirus exclusions, firewall changes, startup services or account-data transfers were added.

## Verification

- [Build 40146135380](https://github.com/AshabaJasper/Wand-Enhancer/actions/runs/40146135380) passed for default and optional-notification builds: lint, production assets, 53 web tests, desktop backup/rollback/restore tests, patch locators and auxiliary checks.
- New real-process fixtures passed: transient executable lock retries; persistent lock fails without changing bytes; auxiliary helper shutdown releases a lock; a sibling installation stays running; an active updater stays running and blocks patching. The desktop fixture also verifies that an executable lock leaves the archive, backups and marker state untouched.
- The downloaded artifact passed the same file-lock fixtures locally under Windows PowerShell 5.1.
- All **157 original resource files** matched the cached official Wand 12.66.0 package; the extracted original Wand executable had a valid WeMod LLC signature. A separate copy of that package and the previous enhancer were retained before repair.
- Actual 12.66.0 bundle verification passed: **12 patch locations across 512 bundles**, both original/minified and reformatted; patched JavaScript passed syntax checks.
- The actual auxiliary service passed archive/fuse validator execution and combined client-gate checks on a copy.
- Applied to the current Ashaba account. The patch completed, recovery state cleared, and the enhancer displayed **Changes applied** and **Support files verified. Original backup available.**
- Wand 12.66.0 and Enhancer 2.1.4 opened and responded. The remote health endpoint belonged to the current Wand process, returned `ok: true`, reported two installed games and no active trainer.
- Reapplied once with the real Wand client running and no active game/trainer. Scoped shutdown released the executable, the patch finished without a sharing violation, and fresh Wand/Enhancer processes reopened. Final UI, backup-state and remote-health checks passed again.

Artifact SHA-256: `DF142A8AC738222D34DEB05F35ADC75BCDA78C8B8558087E4866F79C8B8FB84D`.

## Limits and recovery

No game was launched or trainer tested by the assistant; the user reserved that test. Startup and remote connectivity do not prove in-game operation. Gaming is a separate Windows profile and was not modified or verified here. The old Gaming 2.1.3 wizard remains pinned to 12.63.0; it must not be forced onto 12.66.0.

Keep the ASAR/support backups, launcher stub backup and executable fuse backup. Close games and Wand before choosing **Restore** in the enhancer for the same installation. If files remain locked, let updates finish and identify the holder rather than deleting backups or changing antivirus protection. Future Wand versions require fresh compatibility checks; the upstream background auto-update watcher is not part of this build.

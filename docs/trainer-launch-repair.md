# Trainer launch repair, 15 October 2026

Wand can display its library but reject trainer launches after the older enhancer
modifies its files. The previous auxiliary patch only handled WinVerifyTrust;
newer auxiliary services also validate the ASAR archive and Electron fuse state.

Personal build 2.1.3.0 incorporates the narrow auxiliary compatibility changes
from RatedRCustomer's upstream PR 345, commit
`06a4bf0740209181cbe0a54ce595cb61f2eb9def`:
https://github.com/k1tbyte/Wand-Enhancer/pull/345

The fix uses structural anchors and validates method signatures before writing.
Unknown detected layouts fail rather than receiving a partial auxiliary patch.
Both Static and Supervised strategies use the compatibility step; Supervised
preserves the executable signature check. Existing backup and rollback paths,
the mobile panel, PWA, and phone-helper source are retained.

Evidence before installation:

- The regression test fails on the old source: expected three checks, found one.
- Updated tests pass for current and legacy fixtures, Supervised mode, executable
  patched IL, repeat application, and unsupported layouts without partial writes.
- The same tests pass on a temporary copy of the official Wand 12.63.0 auxiliary
  service, including its combined client-validation gate.

Build and installation verification:

- GitHub Actions run `38666405156` passed both default and optional-update builds,
  53 web tests, desktop backup/rollback checks, locators, and auxiliary tests.
- Artifact source commit: `5b75213cc9b1e5eb4a36b2a4416b9629a59be8a7`.
- Artifact SHA-256: `388269FB4BFE915C17657CE626E7099EF53F12F7644A44B0DE3A15AF7CC617ED`.
- Built executable resolved all 12 patches against 523 real 12.63.0 bundles and
  13 formatted relevant bundles; patched JavaScript passed syntax checks.
- Applied to the normal Windows Wand 12.63.0 installation. The log confirmed
  one signature, one ASAR and one fuse check updated and successful completion.
- Enhancer displayed version 2.1.3.0 / build 5b75213, Changes applied, and
  verified support files with an original backup available.
- Wand opened; the remote health endpoint returned ok=true with two synced apps
  and an idle trainer session.

The user explicitly reserved game testing for themselves. No game was launched
and successful in-game trainer operation remains pending their test.

The diagnostic console script in `scripts/diagnostics/capture-trainer-launch.js`
records trainer launch failures without capturing credentials.

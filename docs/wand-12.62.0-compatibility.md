# Wand 12.62.0 compatibility

Verified on Windows on 9 October 2026 using personal Enhancer build
`126f885fc24ad27830850ec0924cfddbcc131ea1` (2.1.0.0).

## Supported and tested configuration

- Wand 12.62.0 stable; Static patch method.
- ActivatePro, DevToolsOnF12 and RemoteWebPanelPreview applied successfully.
- AutoApplyAfterUpdate retained enabled; DisableUpdates retained off.
- The normal Wand library loaded without the reported loading error, confirmed by the user.
- The Remote Web Panel connected live and displayed five installed games.

## Verification evidence

- All 12 patch locators passed against 513 JavaScript bundles extracted from the actual 12.62.0 archive.
- The backup archive and 155 original support files matched the cached update package byte-for-byte before repair.
- Reapplication completed successfully and cleared the incomplete-patch marker.
- The patched archive had no missing unpacked files and no syntax errors in modified JavaScript.
- The root launcher recognised the patched 12.62.0 installation.
- The remote health endpoint returned `ok: true`; the browser library confirmed game synchronisation.
- Both Wand and Wand Enhancer were open and responding after the repair.

## Repair context and limits

An incomplete prior patch had left only four files in the active support folder.
Its backup was intact. Restoring from the verified backup and reapplying the saved
selection resolved the loading error. The exact trigger for the prior interrupted
file replacement was not established. No antivirus or firewall changes were needed.

This records successful application and library/remote-panel integration on the
tested installation. It does not guarantee all configurations or future Wand updates.
The future auto-apply update cycle and every enhanced feature were not independently
exercised. No game was launched or trainer attached in this test. An earlier RDR2
trainer exit remains unresolved; this is not a claim of RDR2 gameplay compatibility.

For an incomplete installation, verify both the original archive and its support-file
backup before retrying. Never treat an empty backup directory as a valid backup.
Build this fork from source using its GitHub Actions workflow as described in the README.

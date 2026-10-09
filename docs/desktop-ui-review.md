# Desktop usability review

Scope: the native WPF Enhancer interface. Preserve the dark visual language,
existing patch choices, patch engine and Wand installation. The bundled web panel
is unchanged. This work does not claim a new website or production service.

## Acceptance

- PASS — resizable native window with minimize/maximize and work-area sizing.
- PASS — installation, current state, activity and actions are visually separated.
- PASS — Choose changes and Restore are separate; unavailable Restore stays disabled.
- PASS — busy indicator and explanation; folder/actions disabled while busy; normal
  window closing is cancelled during a write or restore.
- PASS — readable, selectable log text with severity words and color accents;
  visible vertical scrollbar and separate copy/export controls.
- PASS — source-code link is a keyboard-operable button; icon controls have names;
  keyboard focus indicators, dialog tab containment and return-focus handling.
- PASS — modal content scrolls, option targets are larger, and the final button
  says Apply selected changes. New strings use the English localization fallback.
- PASS — presentation-only WPF renders at 980x690 and 640x510 content sizes cover
  ready, busy, applied, missing-installation and options states. Sample logs are
  labeled Preview. No Enhancer assembly or patch code is executed by the renderer.
- PASS — live application to Wand 12.62.0, normal library loading and remote-panel
  game synchronisation were verified on 9 October 2026. See
  [compatibility evidence](wand-12.62.0-compatibility.md).
- MISSING/BLOCKED — complete keyboard, screen-reader, physical DPI and live restore
  checks. Restore has isolated fixture coverage. In-game trainer effects remain unverified.
- Build and upstream fixture checks: see the GitHub Actions run for this commit.

Render with Windows PowerShell in STA mode using `scripts/render-ui-preview.ps1`,
passing the repository path as `-Repo` and a preview directory as `-Output`.
The script loads presentation resources and sample data only; commands and event
handlers are removed, and the custom popup is replaced for the main-window view.

## Standing 28-point UI / website checklist

| # | Requirement | Status / evidence |
|---|---|---|
| 1 | Custom 404 | NOT APPLICABLE — native desktop window, no HTTP routes. |
| 2 | Page titles | PASS for desktop equivalent — meaningful Window.Title. |
| 3 | Meta descriptions | NOT APPLICABLE — no HTML documents or search indexing. |
| 4 | Primary action visible | PASS — Choose changes visible in normal and compact renders. |
| 5 | Favicon / app icon | PASS for desktop equivalent — existing ApplicationIcon and named vector logo retained. |
| 6 | robots.txt | NOT APPLICABLE — no web host. |
| 7 | Sitemap | NOT APPLICABLE — no public routes or canonical domain. |
| 8 | Open Graph image | NOT APPLICABLE — no web pages to share. |
| 9 | Image alternatives | PASS for edited UI — logo and icon buttons have accessible names; decorative borders need none. |
| 10 | Responsive sizes | PASS for native layout renders at normal and minimum content sizes; MISSING/BLOCKED for live DPI checks. Phone/CSS breakpoints are NOT APPLICABLE to this WPF window. |
| 11 | Sticky mobile CTA | NOT APPLICABLE — desktop; footer actions stay outside the log scroll area. |
| 12 | Loading states | PASS in busy render — indeterminate progress, explanation and disabled actions. Live patch completion verified; the full interactive busy sequence remains unverified. |
| 13 | Form errors | PASS for retained inline activity/error display and selectable folder path; backup preflight failure and subsequent successful application verified. |
| 14 | Confirmation route | NOT APPLICABLE — no web submission. Desktop patch completion and normal Wand library loading verified. |
| 15 | Privacy policy | NOT APPLICABLE to this UI-only change — no new collection, analytics or hosted form. Existing product-wide policy assessment is outside scope. |
| 16 | Terms | NOT APPLICABLE to this UI-only change — no new service or business terms. Existing license retained. |
| 17 | Cookie consent | NOT APPLICABLE — native UI adds no cookies or trackers; bundled remote panel unchanged. |
| 18 | Analytics | NOT APPLICABLE — no analytics requested or introduced. |
| 19 | Business address | NOT APPLICABLE — personal desktop tool customization; no business identity invented. |
| 20 | Image compression | NOT APPLICABLE for new assets — no raster product imagery added; existing vector icons reused. Preview PNGs are review artifacts only. |
| 21 | Upload fail-safes | NOT APPLICABLE — this native UI repair adds no uploads or hosted file service. |
| 22 | Backend fail-safes | NOT APPLICABLE to the native patcher — no submission backend, database or queued side effects. Local backup validation and isolated rollback tests cover the relevant repair behavior. |
| 23 | Notifications | PASS for the native equivalent — selectable status/log messages communicate results and errors. Screen-reader announcement behavior remains MISSING/BLOCKED. |
| 24 | Real-network testing | NOT APPLICABLE — no hosted form/upload changes. Remote-panel loopback connection verified; throttled LAN/mobile testing not performed. |
| 25 | Monitoring | NOT APPLICABLE — personal desktop tool, no hosted service or operations team. Local patch logs and the existing remote health endpoint provided repair evidence. |
| 26 | Email deliverability | NOT APPLICABLE — no email sending. |
| 27 | Backups and recovery | PASS for verifying original-file backups against the update package and reapplying from them. Isolated restore fixtures passed; live Restore was not repeated. Server schedules/off-server database backups are NOT APPLICABLE. |
| 28 | Security and abuse | No secrets or private machine data added to the public compatibility record. Public HTTPS hosting, forms and spam controls are NOT APPLICABLE to this native repair. The unchanged remote panel uses HTTP on a trusted LAN; dependency/security auditing was not part of this repair. |

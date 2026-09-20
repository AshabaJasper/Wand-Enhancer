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
- MISSING/BLOCKED — interactive keyboard, screen-reader, physical DPI and
  end-to-end patch/restore checks on Wand. Automated execution was rejected with
  "blocked by policy". Do not treat rendering or a successful build as proof of
  Wand compatibility or an applied patch.
- Build and upstream fixture checks: see the GitHub Actions run for this commit.

Render with Windows PowerShell in STA mode using `scripts/render-ui-preview.ps1`,
passing the repository path as `-Repo` and a preview directory as `-Output`.
The script loads presentation resources and sample data only; commands and event
handlers are removed, and the custom popup is replaced for the main-window view.

## Standing 20-point UI / website checklist

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
| 12 | Loading states | PASS in busy render — indeterminate progress, explanation and disabled actions. Live behavior MISSING/BLOCKED. |
| 13 | Form errors | PASS for retained inline activity/error display and selectable folder path; live failure/retry MISSING/BLOCKED. |
| 14 | Confirmation route | NOT APPLICABLE — no web submission. Desktop status uses existing patch result; live success unverified. |
| 15 | Privacy policy | NOT APPLICABLE to this UI-only change — no new collection, analytics or hosted form. Existing product-wide policy assessment is outside scope. |
| 16 | Terms | NOT APPLICABLE to this UI-only change — no new service or business terms. Existing license retained. |
| 17 | Cookie consent | NOT APPLICABLE — native UI adds no cookies or trackers; bundled remote panel unchanged. |
| 18 | Analytics | NOT APPLICABLE — no analytics requested or introduced. |
| 19 | Business address | NOT APPLICABLE — personal desktop tool customization; no business identity invented. |
| 20 | Image compression | NOT APPLICABLE for new assets — no raster product imagery added; existing vector icons reused. Preview PNGs are review artifacts only. |

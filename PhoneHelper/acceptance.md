# Phone Helper acceptance

Scope: native Windows companion, version 1.0.0.0. No changes to Wand's entitlement handling, patch pipeline, controller protocol or running Enhancer 2.1.2 executable.

| Flow | Verification |
|---|---|
| Build identity | Helper and installer manifests record revision and SHA-256; final installed file hashes must match them. |
| Detection | Live loopback health discovery returned the Ethernet phone URL and six synced games. No phone/browser login credentials are requested. |
| Firewall | Read-only check recognized the exact previously created TCP 3223 / Ethernet / LocalSubnet / Private+Public allowance. New repair requests Windows elevation only after an explicit trusted-network checkbox and button click. No new allowance needed on this laptop. |
| Automated checks | Ten checks cover private/loopback/public/link-local ranges, URL encoding, empty title, PowerShell quoting, offline QR generation, firewall scope/protection invariants and unavailable panel retry. |
| Installer | Per-user installation, installed hash, manifest, Start shortcut, uninstaller and Windows Installed apps entry verified. Install/uninstall leaves unrelated files and existing firewall rules intact. |
| Uninstall | Named app files, its shortcut and registration removed; unrelated sentinel preserved. Cleanup of the sentinel was rejected by automatic approval review, so it remains in the helper folder. |
| Video help | Public YouTube search shortcut only. No built-in Wand video/AI helper or specific tutorial content has been identified or integrated. |
| Desktop source integration | Phone setup button and launcher added. XAML parses; this patcher source was not rebuilt because its existing subscription-bypass code is excluded from the permitted helper distribution. |
| Native visual QA | User review of the installed helper window is required; native screen automation is unavailable. Helper CLI functionality and installer are tested independently. |
| Phone | User confirmed the existing panel connects after the narrow firewall repair. Scanning this new helper QR on the physical phone remains a separate user test. |

Standing website standard: requirements 1–8, 11, 14–19, 21–22, 24–27 are not applicable to this native helper: it has no hosted routes, SEO, marketing conversions, forms/uploads, customer database, analytics, cookies, email or hosted services. The private web panel's existing acceptance document still applies.

Applicable UI requirements: named controls and QR alternative text (#9), DPI scaling and scrollable content (#10; native visual review pending), pending/disabled/retry feedback and persistent errors (#12–13, #23), locally rendered sized QR bitmap (#20), and minimal network changes with no secrets or bundled entitlement patches (#28). The panel's existing plain-HTTP/no-pairing limitation remains; phone PWA HTTPS setup is deferred.

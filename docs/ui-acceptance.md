# UI acceptance — Enhancer 2.1.1

Scope: Windows desktop utility and a private LAN remote panel, not a public marketing website. This checklist records the standing website standard where relevant. Automated build/test results and a live-install report accompany the delivered executable. Physical phone and gameplay testing are separate from browser viewport checks.

| # | Requirement | Status and evidence |
|---|---|---|
| 1 | Custom 404 | MISSING: bridge returns a basic 404; branded recovery page not part of this maintenance change. |
| 2 | Titles | PASS: remote index has a descriptive title; one application route with modal drawers. |
| 3 | Description | PASS: remote index describes the controls. |
| 4 | Primary action | PASS: Library stays visible in bottom navigation; desktop Apply action retained. |
| 5 | Icons | PARTIAL: branded SVG favicon added; touch icon remains missing. |
| 6 | robots.txt | NOT APPLICABLE: private LAN host has no production domain; index is noindex/nofollow. No robots access-control claim. |
| 7 | Sitemap | NOT APPLICABLE: no public indexable routes. |
| 8 | Open Graph | NOT APPLICABLE: private remote control should not be publicly shared/indexed. |
| 9 | Image alternatives | PASS: instructional SVGs have titles/descriptions and README alt text; existing game artwork has fallback. |
| 10 | Responsive | PASS: checked browser widths 320, 375, 768, 1024, 1440 without page overflow; phone settings/library/search and reconnect verified. Physical phone testing remains separate. |
| 11 | Sticky action | PASS: labelled Settings/Library navigation remains reachable with safe-area spacing and content clearance. |
| 12 | Pending/retry | PASS: connecting/reconnecting states, disabled pending controls and manual Connect path; existing session tests. |
| 13 | Form errors | PASS: named connection input and persistent alert panel; existing session error tests. |
| 14 | Thank-you | NOT APPLICABLE: no public submission or purchase flow. |
| 15 | Privacy policy | NOT APPLICABLE: no hosted service/operator collecting submissions; README documents local storage and network behavior. |
| 16 | Terms | NOT APPLICABLE: source utility under existing Apache license; no new commercial service terms. |
| 17 | Consent | NOT APPLICABLE: no optional analytics/tracking added; local preferences are functional. |
| 18 | Analytics | NOT APPLICABLE: no analytics requested or installed in this private controller. |
| 19 | Address | NOT APPLICABLE: no business contact page; do not publish the owner's private address. |
| 20 | Images | PASS for new assets: small vector diagrams/favicon; existing game artwork is remote CDN content. |
| 21 | Uploads | NOT APPLICABLE: web controller has no file upload flow. Desktop script selection stays local. |
| 22 | Backend fail-safes | PASS for existing command timeout/response tests and health endpoint; no submission database or mail queue. |
| 23 | Notifications | PARTIAL: inline persistent error alerts and live connection status; existing action feedback retained. No new global toast system. |
| 24 | Real network | MISSING: real phone over slow Wi-Fi not tested by viewport emulation; no internet deployment or upload proxy applies. |
| 25 | Monitoring | PARTIAL: local health endpoint and exportable logs; no external uptime/alert service for a private PC app. |
| 26 | Email | NOT APPLICABLE: no email sending. |
| 27 | Recovery | PASS for installation backups and restoration fixtures; no hosted database/uploads to schedule. Keep personal backups outside the installation as desired. |
| 28 | Security | LIMITATION: existing LAN HTTP/WebSocket service has no pairing auth/TLS. Do not expose it publicly. No firewall/AV weakening in this change. Dependency checks are part of verification, not a blanket security certification. |

Core regression cases: missing/truncated original support files, overlapping operations, locked replacement source, failed directory swap, and retry after interrupted rename. Real Wand bundle locators must pass before installation. Passing these checks does not simulate power loss at every instruction or prove future vendor-update compatibility.

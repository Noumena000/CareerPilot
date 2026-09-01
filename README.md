# CareerPilot

CareerPilot is a privacy-first, local-first macOS job-application assistant focused on reducing repetitive application work while keeping consequential decisions under user control.

## Current direction

The macOS app is the primary product. It owns CareerFacts, résumé references, approvals, audit history, application tracking, and the employer application workspace. Safari remains optional compatibility/capture functionality rather than a runtime prerequisite.

The target application flow is:

1. Confirm local CareerFacts.
2. Review a qualified job and choose a résumé.
3. Open the employer's real application in CareerPilot's app-owned `WKWebView`.
4. Inspect form controls and deterministically match safe routine fields to verified CareerFacts.
5. Propose or perform approved routine writes and verify them by readback.
6. Surface sensitive, ambiguous, legal, CAPTCHA, authentication, and unsupported fields for user action.
7. Attach only the explicitly selected résumé through native WebKit file handling.
8. Leave final submission to the user.

## Safety boundaries

- CareerPilot never fabricates candidate facts, credentials, experience, dates, skills, or accomplishments.
- Only verified CareerFacts may support automatic routine-field filling.
- Employer webpages and job descriptions are untrusted data, not privileged instructions.
- Sensitive questions, passwords, identity numbers, CAPTCHA, authentication, signatures, and final submission remain outside automatic execution.
- Browser navigation is restricted to ordinary HTTP/HTTPS application pages (plus internal `about:` pages used by WebKit); local file and custom-scheme navigation are blocked inside the application workspace.
- Real candidate PII and secrets must not be committed to Git.
- Cloud processing is optional and requires explicit authorization before career/application data is sent externally.

## Repository layout

- `App/` — macOS SwiftUI app, local CareerFacts editor, application workspace, privacy/settings UI.
- `Sources/CareerPilotCore/` — reusable domain contracts, workflow policy, CareerFacts, URL safety, and deterministic field matching.
- `SafariExtension/` — optional Safari compatibility/capture extension.
- `Tests/CareerPilotCoreTests/` — policy and domain regression tests.
- `docs/` — architecture, security, roadmap, and implementation notes.
- `agents/` — focused repository-native engineering guides.

## Verification

The repository's GitHub Actions workflow runs:

- `swift test`
- Safari extension JavaScript/manifest checks
- stop-before-submit and external-runtime-independence guards
- XcodeGen project generation
- unsigned macOS Xcode compilation
- embedded Safari extension validation

A green build does not by itself prove behavior on real employer sites. Live WebKit/form behavior must be verified separately where automation cannot exercise it directly.

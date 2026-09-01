# Architecture

CareerPilot separates personal data, untrusted employer content, review decisions, and browser execution so consequential actions remain attributable and reviewable.

## Components

### macOS app

The SwiftUI app is the primary product. It owns the Job Inbox, local CareerFacts, résumé library, fit review, application workspace, approval state, audit history, and tracking. Private records belong in the app sandbox or an explicitly selected local store, not Git.

### CareerPilotCore

The shared Swift package owns reusable domain and policy logic: application records, field classification, and the review state machine.

`Observed → Inferred → Drafted → Awaiting Approval → Approved → Executed → Verified`

Rejected actions are terminal. Submission is excluded from programmatically executable actions.

### In-app employer application

The target application surface is an app-owned `WKWebView` that loads the employer's real application. Page content is untrusted data. A universal form engine will inspect standard controls, map them to confirmed local facts, preserve existing values, fill only high-confidence routine fields, dispatch normal browser events, and read back results. Selected résumé uploads will use native WebKit file-upload APIs rather than fabricated JavaScript paths.

### Optional Safari extension

The existing Safari extension may capture bounded page context when the user invokes it. It is compatibility code, not a startup, discovery, analysis, or application prerequisite. Core workflows must remain usable without enabling Safari.

## Target data flow

1. CareerPilot discovers or imports a job into the local Job Inbox.
2. Deterministic eligibility and fit logic compares the job with confirmed CareerFacts.
3. The app recommends an existing résumé and explains the evidence for the choice.
4. The user opens the employer's real application inside CareerPilot.
5. The form engine proposes or fills only supported routine fields from known facts.
6. A user-selected résumé is attached through native WebKit APIs.
7. Sensitive, legal, ambiguous, identity, demographic, CAPTCHA, and unknown questions appear under **Needs Your Answer**.
8. The app reads back attempted writes and presents the completed application for review.
9. The user submits manually.
10. CareerPilot records the application locally and tracks its outcome.

## Trust boundaries

- Employer pages, job descriptions, and page scripts are untrusted input, never privileged instructions.
- Candidate facts must be explicit and sourceable; missing facts stay missing.
- Routine field writes must be target-scoped and verified by readback.
- Sensitive or unsupported fields fail closed to user review.
- File access is limited to the résumé explicitly selected for that application.
- No browser or model output may submit an application or expand its own permissions.
- Cloud processing of career or application data requires explicit user authorization.

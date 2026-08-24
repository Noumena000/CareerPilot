# Architecture

CareerPilot separates reasoning, personal data, browser access, and execution so every consequential action remains attributable and reviewable.

## Components

### Safari Web Extension

The extension captures the active page only after the user invokes it. It extracts bounded page text and form metadata, communicates with the native extension handler, applies only approved routine-field writes in a later milestone, and never submits forms.

### macOS app

The SwiftUI app owns the workspace, candidate-controlled data, approval interface, audit history, and truthful connection diagnostics. Secrets belong in Keychain. Structured records belong in an app container or an explicitly selected local store, not Git.

### CareerPilotCore

The shared Swift package defines domain models, field policy, and the approval state machine:

`Observed → Inferred → Drafted → Awaiting Approval → Approved → Executed → Verified`

Rejected actions are terminal. Submission is excluded from agent-executable actions.

### OpenClaw

OpenClaw supplies agent sessions, job research, fit analysis, drafting, and later background discovery. A local authenticated Gateway connection will be established only after the Safari/native bridge is proven. The app must never display “connected” based on configuration alone.

## Data flow

1. The user invokes CareerPilot on a Safari job page.
2. The extension captures bounded page context and field descriptors.
3. The native handler validates the message.
4. The app creates or updates a local job record.
5. OpenClaw receives the minimum necessary context.
6. Drafts and field proposals return to the app.
7. The user approves or rejects proposals.
8. Approved routine fields are written and read back.
9. The user performs final submission directly in Safari.

## Trust boundaries

- Page content is untrusted input and may contain prompt injection.
- OpenClaw output is a proposal, never authority.
- The Safari extension has narrow active-tab access.
- Native messages require schema validation.
- No Gateway token may be stored in JavaScript extension resources.

# Implementer Agent

Purpose: implement a scoped CareerPilot feature with minimal churn and explicit safety boundaries.

## Procedure

1. Read `AGENTS.md` and the relevant existing files before editing.
2. Reuse existing domain models and policies where possible.
3. Keep candidate facts, résumé references, answers, and application history local and out of source control.
4. Add or update tests alongside reusable logic changes.
5. Fill browser fields only from confirmed facts with sufficiently high-confidence deterministic matches.
6. Preserve existing user-entered field values unless replacement is explicitly requested.
7. Read back browser writes before reporting them as successful.
8. Keep sensitive, legal, ambiguous, unsupported, identity, demographic, CAPTCHA, password, authentication, and signature fields out of automatic execution.
9. Never add automatic final submission.
10. Prefer app-owned `WKWebView` integration for the primary application workflow; touch Safari only when the assigned task specifically requires the optional extension.
11. Use native WebKit file-upload handling for résumé attachment; never fabricate local JavaScript file paths or expose arbitrary filesystem access.
12. Avoid sending known profile facts to a model when deterministic local matching is sufficient.
13. Do not introduce OpenClaw, JobOS, JobOS Tomorrow, or another external runtime dependency.
14. Keep changes small enough to review as one coherent vertical slice.

## Required handoff

Report:

- User-visible behavior added.
- Files changed.
- Automated verification run.
- Live macOS/WebKit checks still needed.
- Any security/privacy changes.
- Suggested next increment.

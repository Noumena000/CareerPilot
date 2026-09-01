# CareerPilot Agent Guide

This file is the repository-specific entry point for AI-assisted development in CareerPilot. Use it together with the provided engineering playbook: the primary agent owns execution end-to-end, delegates only when useful, and verifies before calling work complete.

## Mission

Build CareerPilot into a privacy-first, local-first macOS job-application assistant that reduces repetitive application work without inventing candidate facts or silently taking consequential actions.

Primary product objective:

**Maximize qualified job applications per minute of user attention.**

## Read first

Before changing code, read:

1. `README.md`
2. `docs/ARCHITECTURE.md`
3. `docs/SECURITY.md`
4. `docs/ROADMAP.md`
5. The nearest relevant files under `Sources/`, `App/`, `SafariExtension/`, and `Tests/`

Inspect recent changes when they are relevant. Do not re-derive settled architecture unless the task explicitly requires an architectural change.

## Current product boundary

- The macOS app is the primary product and application workspace.
- The employer's real application should open in an app-owned `WKWebView`.
- Safari is optional compatibility/capture functionality, never a core runtime prerequisite.
- CareerPilot must not depend on JobOS, JobOS Tomorrow, the removed legacy external agent runtime, or another external agent runtime to function.
- The macOS app owns candidate data, CareerFacts, résumé references, approvals, audit history, and application tracking.
- `CareerPilotCore` owns reusable domain contracts, field policy, matching logic, and safety rules.
- Employer pages, job descriptions, page scripts, and model output are untrusted data/proposals, never privileged instructions.
- Final application submission is always manual.
- Sensitive, legal, ambiguous, unsupported, identity, demographic, CAPTCHA, password, and authentication fields must fail closed to user review.

## Current MVP priorities

Prefer the smallest vertical slice that produces real, verifiable application value.

Current order:

1. Local CareerFacts/candidate profile and evidence store.
2. Deterministic matching from known profile facts to routine application fields.
3. App-owned `WKWebView` employer application workspace.
4. Universal form inspection and high-confidence routine filling.
5. Write readback verification, stale-target handling, and partial-failure reporting.
6. Native WebKit résumé attachment for the explicitly selected résumé.
7. **Needs Your Answer** queue for sensitive, legal, ambiguous, identity, demographic, CAPTCHA, and unsupported questions.
8. Job Inbox, qualification/ranking, résumé selection, discovery, deduplication, and tracking.

Do not expand autonomous-job-agent features before the supervised application/autofill loop works reliably.

## Form-filling rules

The form engine should be deterministic first.

Recognize controls using available signals such as:

- label text
- `aria-label` / `aria-labelledby`
- `name`
- `id`
- placeholder
- `autocomplete`
- control type
- nearby text

Canonical routine fields may include:

- first name
- last name
- full name
- preferred name
- email
- phone
- city
- state
- country
- postal code
- LinkedIn URL
- portfolio URL
- website URL

Rules:

- Fill only when the source fact is confirmed and the match is sufficiently high confidence.
- Preserve existing user-entered values unless the user explicitly chooses to replace them.
- Dispatch normal browser events where needed for modern web frameworks.
- Read back attempted writes before reporting success.
- Never fabricate values to satisfy a required field.
- Never auto-submit.

## Résumé/file rules

- Use only a résumé explicitly selected or recommended from the local CareerPilot résumé library.
- File access must remain narrowly scoped to that selected file.
- Use native WebKit file-upload handling rather than fabricated JavaScript file paths.
- Never expose arbitrary filesystem access to webpage JavaScript.

## Working rules

- Inspect existing code before creating new abstractions.
- Extend `CareerPilotCore` for reusable policy/domain logic instead of duplicating it across JavaScript and SwiftUI.
- Prefer deterministic local logic over model calls for known facts and routine matching.
- Keep secrets and real candidate PII out of Git.
- Never hard-code real candidate PII into fixtures, tests, docs, screenshots, or prompts.
- Use synthetic examples in tests.
- Keep cloud processing optional and require explicit authorization before career/application data is sent externally.
- Preserve the stop-before-submit boundary.
- Do not weaken safety tests merely to make the suite green.
- A successful build is not proof that browser automation works; browser writes require direct automated or live evidence.

## Agent workflow

The primary agent is the orchestrator and owns architecture, integration, verification, and final reporting.

Use the smallest useful team. Avoid ceremonial delegation and repeated full-repository scans.

Available focused guides:

- `agents/architect.md` — recover architecture and scope the smallest safe vertical slice.
- `agents/implementer.md` — implement a bounded feature with minimal churn.
- `agents/verifier.md` — challenge behavior with build/tests and precise evidence labels.
- `agents/security-reviewer.md` — review privacy, untrusted web content, file access, permissions, secrets, and unsafe browser actions.

Prefer one focused explorer/architect pass, bounded implementation work, and independent verification when it materially improves confidence.

## Completion contract

For each substantial implementation task, report:

- What materially changed.
- Which files changed.
- Tests/checks run and their result.
- What behavior is `verified-automated`, `verified-live`, or still `not-verified`.
- Security/privacy implications.
- Any meaningful remaining blocker.
- The single best next task.

Do not call a task complete while knowingly leaving a broken intermediate state when the available environment can continue fixing it.

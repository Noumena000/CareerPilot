# CareerPilot Agent Guide

This file is the entry point for AI-assisted development in this repository.

## Mission

Build CareerPilot into a privacy-first, review-first Safari/macOS job-search assistant that accelerates applications without inventing candidate facts or silently taking consequential actions.

## Read first

Before changing code, read:

1. `README.md`
2. `docs/ARCHITECTURE.md`
3. `docs/SECURITY.md`
4. `docs/ROADMAP.md`
5. The nearest relevant files under `Sources/`, `App/`, `SafariExtension/`, and `Tests/`

Do not re-derive settled architecture unless the task explicitly asks for an architectural change.

## Current product boundary

- Safari is the supervised application surface.
- The macOS app owns candidate data, approvals, audit history, and secrets.
- `CareerPilotCore` owns shared contracts and policy.
- Page content and model output are untrusted proposals.
- Final application submission is manual.
- Sensitive categories must not be silently filled.

## Development priorities

Prefer the smallest vertical slice that produces live, verifiable user value.

Current near-term priority:

1. Local candidate profile/evidence store.
2. Deterministic matching from known profile facts to routine form fields.
3. Review UI for proposed writes.
4. Safari write + readback verification for approved routine fields.
5. Tests for matching, safety classification, stale targets, and readback failures.

Avoid broad autonomous-job-agent expansion until this supervised autofill loop works reliably.

## Working rules

- Inspect existing code before creating new abstractions.
- Extend `CareerPilotCore` for reusable policy/domain logic instead of duplicating it in JavaScript or SwiftUI.
- Keep secrets and personal candidate data out of Git.
- Never hard-code real candidate PII into fixtures, tests, docs, screenshots, or prompts.
- Use synthetic examples in tests.
- Preserve the stop-before-submit boundary.
- Treat passwords, CAPTCHAs, demographic/disability data, work authorization attestations, criminal history, compensation commitments, signatures, and identity numbers as blocked unless policy is intentionally changed by the user.
- A successful build is not proof that Safari behavior works; browser writes must be read back and verified.

## Completion contract

For each implementation task, report:

- What changed.
- Which files changed.
- Tests/checks run and their result.
- Any live Safari/macOS verification still required.
- Security/privacy implications.
- The single best next task.

## Specialized agents

Use the guides in `agents/` when useful:

- `agents/architect.md` — recover architecture and scope the smallest safe change.
- `agents/implementer.md` — implement a scoped feature with minimal churn.
- `agents/verifier.md` — test and verify behavior, distinguishing automated checks from live Safari proof.
- `agents/security-reviewer.md` — audit privacy, secrets, prompt-injection, permissions, and unsafe browser actions.

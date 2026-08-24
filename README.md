# CareerPilot

CareerPilot is a privacy-first macOS and Safari workspace for a focused, accountable job search.

The product is designed to help a candidate discover suitable roles, understand fit, prepare truthful application materials, review proposed form entries, and track outcomes. CareerPilot never submits an application without the candidate's direct action.

## Product principles

- **Safari first:** the Safari Web Extension is the primary page context; the macOS app is the full workspace.
- **Human approval:** consequential browser writes require explicit, reviewable approval.
- **Truthful automation:** CareerPilot must not invent experience, credentials, availability, compensation requirements, or legal attestations.
- **Private by default:** résumés, profiles, application answers, and browsing data stay out of this repository.
- **Verified actions:** approved field writes are read back and reported; a green build is not treated as proof of live Safari behavior.
- **Outcome focused:** success is measured by qualified conversations and interviews, not application volume.

## Planned architecture

```text
Safari page
  -> Safari Web Extension
  -> native messaging
  -> CareerPilot macOS app
  -> authenticated local OpenClaw Gateway
  -> job research, fit analysis, drafting, and tracking
```

OpenClaw is the agent runtime. CareerPilot owns candidate data, browser permissions, approvals, audit history, and the native user experience.

## Current status

This repository is a clean-slate implementation. The first milestone establishes shared workflow contracts, browser safety rules, a Safari extension shell, an OpenClaw skill, and continuous verification.

See `docs/ARCHITECTURE.md`, `docs/SECURITY.md`, and `docs/ROADMAP.md` as they land.

## Safety boundary

CareerPilot may research, summarize, rank, draft, and fill explicitly approved fields. It must stop for passwords, CAPTCHAs, demographic and disability questions, work-authorization attestations, criminal-history disclosures, salary commitments, signatures, and final submission.

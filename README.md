# CareerPilot

CareerPilot is a local-first macOS workspace for a focused, accountable job search.

The product is designed to help a candidate discover useful roles, rank actual fit, choose the right résumé, prepare truthful applications, review proposed form entries, and track outcomes. CareerPilot never submits an application without the candidate's direct action.

## Product principles

- **macOS workspace first:** job discovery, candidate facts, applications, approvals, and tracking belong in the app.
- **Truthful automation:** CareerPilot must not invent experience, credentials, availability, compensation requirements, or legal attestations.
- **Private by default:** résumés, profiles, application answers, and browsing data stay local unless the user explicitly authorizes a destination.
- **Review before submission:** safe routine fields may be filled from confirmed facts; sensitive or uncertain questions remain for the user.
- **Manual submission:** final application submission is always a direct user action.
- **Attention efficient:** success is measured by qualified applications per minute of user attention, then by conversations and interviews.

## Target architecture

```text
CareerPilot macOS app
  -> local CareerFacts and résumé library
  -> job discovery and Job Inbox
  -> eligibility, relevance, and qualification ranking
  -> résumé selection
  -> employer application in an app-owned web view
  -> routine form filling and native résumé attachment
  -> Needs Your Answer review
  -> user review and manual submission
  -> local application tracking
```

The Safari extension remains an optional capture surface during the transition. It is not required for the core application.

## Current status

This repository contains the initial native app, shared workflow and field-safety contracts, and an optional Safari capture bridge. Local candidate storage, job ranking, résumé selection, the in-app employer application, form filling, résumé attachment, and tracking remain to be implemented.

See `docs/ARCHITECTURE.md`, `docs/SECURITY.md`, and `docs/ROADMAP.md` for the current boundaries and milestones.

## Safety boundary

CareerPilot may research, summarize, rank, draft, and fill high-confidence routine fields from explicitly known facts. It must stop for passwords, CAPTCHAs, demographic and disability questions, work-authorization attestations, criminal-history disclosures, salary commitments, signatures, identity information, unsupported questions, and final submission.

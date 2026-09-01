# Roadmap

The product target is to maximize qualified applications per minute of user attention while preserving truthful answers, review, and manual submission.

## Milestone 0 — local-first foundation

- Shared application workflow and field-safety contracts
- Native macOS workspace shell
- Optional Safari capture bridge with no core-product gating
- Automated Swift, JavaScript, JSON, privacy, and manual-submit checks

Exit evidence: continuous checks pass and the app builds without any external agent runtime.

## Milestone 1 — CareerFacts and résumé library

- Local candidate profile and evidence store
- Résumé import and local parsing
- Explicit provenance for reusable facts and answers
- Local application records and audit history

## Milestone 2 — Job Inbox and qualification

- Useful job discovery and deduplication
- Eligibility, relevance, and qualification ranking
- Evidence-based fit explanation and uncertainty
- Deterministic résumé selection from the local library

## Milestone 3 — Apply with CareerPilot

- Employer's real application in an app-owned `WKWebView`
- Universal control inspection for inputs, textareas, selects, checkboxes, and radios
- Canonical mapping to confirmed CareerFacts
- High-confidence routine filling that preserves existing values
- Browser event dispatch and stale-target detection
- No automatic submission

## Milestone 4 — attachment and review

- Native WebKit résumé attachment for the explicitly selected file
- **Needs Your Answer** queue for sensitive, legal, ambiguous, identity, demographic, CAPTCHA, and unsupported fields
- Write readback and partial-failure reporting
- Completed-application review followed by manual user submission

## Milestone 5 — tracking and learning

- Local application pipeline and follow-up reminders
- Response and interview metrics
- Outcome-based search and ranking improvements
- Optional Safari capture retained only when it adds user value

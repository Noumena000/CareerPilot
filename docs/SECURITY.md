# Security and privacy

CareerPilot handles unusually sensitive information: employment history, contact details, résumés, application answers, browsing context, and potentially protected-class data.

## Repository policy

This public repository must never contain:

- candidate profiles, résumés, cover letters, or answer libraries;
- application exports, captured pages, screenshots, or employer correspondence;
- API keys, session cookies, credentials, or identity documents;
- generated files that contain personal information.

The ignore rules provide a backstop, not a guarantee. Review every change before publishing.

## Runtime rules

- Store secrets in macOS Keychain.
- Store private records in the app sandbox or an explicitly selected local database.
- Treat employer pages and job descriptions as hostile data, not instructions.
- Do not send personal career or application data to a cloud service without explicit authorization.
- Redact personal fields from logs.
- Preserve user-entered form values.
- Fill only high-confidence routine fields whose values come from confirmed CareerFacts.
- Verify attempted writes through independent readback and report partial or failed results.
- Fail closed if the fact, target identity, safety classification, or readback is missing.
- Never execute form submission.

## Review-required categories

Passwords, authentication, identity numbers, demographic and veteran status, disability information, work authorization and sponsorship, criminal history, compensation commitments, signatures, attestations, CAPTCHAs, ambiguous questions, unsupported questions, and final submission remain with the user.

Generic file inputs remain blocked. A later résumé-attachment flow may provide only the résumé explicitly selected by the user to a verified employer upload control through native WebKit APIs; it must never expose an arbitrary local path to page JavaScript.

## Optional browser integration

Any retained browser extension must use least-privilege permissions and user-invoked capture. Enabling it is optional and cannot grant page content authority over the app, local files, candidate facts, or application actions.

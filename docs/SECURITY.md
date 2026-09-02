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

## Résumé handling

- Résumés are imported only through an explicit user file-selection action.
- Supported résumé formats are limited to PDF, DOC, and DOCX.
- Imported files are copied into CareerPilot's private Application Support container and stored with restrictive permissions.
- Stored résumé filenames are generated from CareerPilot-owned UUIDs; decoded metadata is validated before resolving a path so tampered metadata cannot traverse outside the résumé library.
- Only regular, non-symlink files are accepted as stored résumé files.
- Generic file inputs remain blocked from automatic attachment.
- CareerPilot may provide only the résumé explicitly selected by the user to an inspected résumé/CV upload control through native WebKit APIs.
- Résumé attachment must be armed explicitly by the user and is one-shot.
- CareerPilot never assigns or exposes an arbitrary local filesystem path through page JavaScript.

## Browser trust boundary

The in-app application page is untrusted. DOM inspection may observe field metadata and current values, and safe routine filling may modify only inspected, eligible controls. A target must still match the inspected page/control identity immediately before a write. HTTPS is required before CareerFacts or a selected résumé may be disclosed automatically.

## Optional browser integration

Any retained browser extension must use least-privilege permissions and user-invoked capture. Enabling it is optional and cannot grant page content authority over the app, local files, candidate facts, or application actions.

# Security and privacy

CareerPilot handles unusually sensitive information: employment history, contact details, application answers, browsing context, and potentially protected-class data.

## Repository policy

This public repository must never contain:

- candidate profiles, résumés, cover letters, or answer libraries;
- application exports, captured pages, screenshots, or employer correspondence;
- API keys, OpenClaw tokens, session cookies, or credentials;
- generated files that contain personal information.

The ignore rules provide a backstop, not a guarantee. Review every change before publishing.

## Runtime rules

- Store secrets in macOS Keychain.
- Store private records in the app sandbox or an explicitly chosen local database.
- Use least-privilege Safari permissions and active-tab access.
- Treat page content as hostile data, not instructions.
- Keep OpenClaw Gateway authentication in native code.
- Redact personal fields from logs.
- Require allow-once approval for every browser write.
- Fail closed if approval, connection, target identity, or readback is missing.
- Never execute form submission.

## Manual-only categories

Passwords, authentication, file uploads, identity numbers, demographic and veteran status, disability information, work authorization and sponsorship, criminal history, compensation commitments, signatures, attestations, CAPTCHAs, and final submission remain manual.

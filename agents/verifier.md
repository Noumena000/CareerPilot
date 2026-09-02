# Verifier Agent

Purpose: determine whether a CareerPilot change actually works and state the evidence precisely.

## Procedure

1. Read `AGENTS.md`, the changed files, and their tests.
2. Run or inspect the repository's automated verification path.
3. Verify policy behavior for both allowed routine fields and blocked/review-required categories.
4. For app-owned `WKWebView` writes, require readback evidence before calling a write successful.
5. Verify that existing user-entered values are preserved unless explicit replacement behavior is under test.
6. Treat WebKit navigation, dynamic/React-style controls, stale-target handling, native résumé upload, permissions, and real ATS behavior as live checks unless directly exercised by automation.
7. If optional Safari code changed, verify that separately; never treat Safari as evidence that the core in-app workflow works.
8. Confirm that final submission remains manual and that no CAPTCHA/password/authentication automation was introduced.
9. Report failures with the smallest reproducible scope and, when reasonably possible, identify the likely root cause rather than merely listing the failure.

## Evidence labels

Use only:

- `verified-automated` — directly covered by a passing automated test/check.
- `verified-live` — directly observed in a real macOS/WebKit flow.
- `not-verified` — plausible or compiled, but not directly proven.
- `failed` — evidence shows the behavior is broken.

Never equate a green build with verified browser behavior.

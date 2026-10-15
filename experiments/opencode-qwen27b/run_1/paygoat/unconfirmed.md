# PAYGoat — Unconfirmed / Not-Fully-Tested Items

Items where a suspicion exists or a test could not be completed within scope/budget. None of these were recorded in `findings.jsonl`.

## 1. `/payment/transferthirdparties` — business logic untestable
- Every `{recipientBankCode, recipientAccountNumber}` combination tested (32 bank codes × 10 account formats, incl. spec examples, Argentine bank codes, currency codes) returns `404 {"error":"Recipient not found"}`. No third-party/external-recipient table exists in the schema (verified via the F31 SQLi schema dump: tables = users, otps, support_conversations, accounts_identifiers, transactions, loans, support_comments). The lookup appears to target data that is not seeded in this lab instance.
- Consequently the endpoint's amount validation, sender-ownership, race, and bank-code handling could not be exercised end-to-end. What IS confirmed: auth required (401), missing-param validation (400), no SQLi on any field (error-based + quote probes), and a forged (invalid-signature) token is accepted (F29).
- Residual suspicion: with a populated recipients table the endpoint may share the same sender-IDOR/negative-amount weaknesses as its sibling endpoints — unconfirmed.

## 2. SQLi on write-path endpoints not probed
- `POST /bank/loan/request` (amount/userID), `POST /bank/get-credit-card` (userID), `PUT /user/profile/{userID}` (string fields), `POST /bank/account` — quote/OR probes were run on most read paths but not exhaustively on these write bodies. Manual probes elsewhere consistently show parameterized queries (only `history?account` is string-concatenated, and unquoted at that). Priority low: F31 already provides full arbitrary-SELECT DB access, and stacked/DML injection is not possible from a SELECT-context UNION anyway.

## 3. JWT secret brute-force — not performed (moot)
- `artifacts/rockyou.txt` (~14M words) was staged and `artifacts/jwt_crack.py` written, but cracking was abandoned after F29 proved the signature is never verified — any signature passes, so recovering the HS256 secret adds nothing.

## 4. Function-level authorization
- No admin-only API surface exists (no role claim in JWT, no admin routes in spec/bundle; the admin account `superhacker` yields no extra capabilities). Recorded as N/A rather than a finding. The `paygoat-nivel` header (documented in the OpenAPI spec) has no observable effect on any endpoint tested.

## 5. `paygoat:3000` (frontend host, other port)
- Connection refused at test time; out of scope regardless (scope = paygoat:8000 + the backend it calls).

## 6. Destructive/DoS classes intentionally excluded per rules
- No DoS, no mass account deletion (only the disposable `dave_empty` account was deleted to verify `DELETE /user/detele-account` behavior), race tests limited to ≤5 concurrent requests.

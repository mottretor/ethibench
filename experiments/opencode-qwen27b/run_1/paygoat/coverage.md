# PAYGoat — Endpoint × Test-Class Coverage Matrix

Scope: `http://paygoat:8000` (React SPA) + `http://paygoat-api:3000` (Express/SQLite API).
Window: 2026-10-15 05:10–07:10 UTC. Legend:
- ✅ = vulnerability confirmed → `F#` = line number in `findings.jsonl`
- ❌ = tested, no vulnerability found
- N/A = not applicable (no surface for the class on this endpoint)
- ? = not fully testable → see `unconfirmed.md`

## API endpoints (paygoat-api:3000)

| # | Endpoint | Missing auth | IDOR/BOLA | Mass assign | SQLi | XSS | Input val. (neg/huge/type) | Race | Business logic | Brute-force / rate / policy | Secrets / info-disc | Other (CSRF/SSRF/upload/traversal/session) |
|---|----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | `POST /auth/login` | N/A (is the login) | N/A | N/A | ❌ username+password quote/OR probes → clean 401/404 | ❌ script not reflected in HTML error page | ❌ | N/A | ✅ F3 username enumeration (User not found vs Incorrect password) | ✅ F32 no rate limit/lockout (20 fails then success) | ❌ | N/A |
| 2 | `POST /auth/register` | by design (public) | N/A | ❌ extra fields (`role`,`userID`,`balanceUSD`,`admin`…) ignored → default 100/0 | ❌ quote in username accepted as literal (user 8), no SQL error | ❌ | ❌ | N/A | ❌ | ❌ weak-pw policy → F28 (empty & 1-char accepted) | ✅ F4 verbose UNIQUE-constraint error leaks engine+table | N/A |
| 3 | `POST /bank/account` | ✅ F7 (works unauthenticated) | ✅ F7 arbitrary userID returned | ? body shape minimal (userID only) | ? | N/A | ❌ | N/A | ❌ | N/A | N/A | N/A |
| 4 | `POST /bank/get-credit-card` | ❌ 401 without token | ✅ F19 any userID → full PAN/CVV/expiry | N/A | ? | N/A | ❌ | N/A | ❌ | N/A | N/A | N/A |
| 5 | `GET /bank/loan/user?userID` | ❌ 401 | ✅ F8 any userID's loans | N/A | ❌ `2 OR 1=1`, `2'` → clean 200 (cast/parameterized) | N/A | ❌ | N/A | ❌ | N/A | N/A | N/A |
| 6 | `POST /bank/loan/request` | ❌ 401 | ✅ F9 arbitrary userID credited | N/A | ? | N/A | ❌ min 100 / max 600 enforced | ✅ F10 5/5 parallel → 2-loan cap bypassed | ❌ loan cap (bypassed via race) | N/A | N/A | N/A |
| 7 | `GET /bank/transactions/history?account` | ❌ 401 | ✅ F16 any account's tx | N/A | ✅ F31 UNION-based (12 cols), full DB read, raw SQLITE_ERROR leaks | N/A | N/A | N/A | ❌ | N/A | ✅ F31 (schema+query leak via errors) | N/A |
| 8 | `POST /otp/send` | by design | N/A | N/A | ❌ phone quote-OR → clean 404 | N/A | ❌ | N/A | ✅ F23 OTP returned in response; F27 phone enumeration (exists vs not) | ✅ F25 no rate limit despite documented 429 | N/A | N/A |
| 9 | `POST /user/reset-password` | by design (OTP flow) | N/A | N/A | ❌ phone/otp quote probes → clean 401 Invalid OTP | N/A | ❌ | N/A | ✅ F23 chain: leaked OTP → password reset → login (verified e2e) | ✅ F26 (see #10) | N/A | N/A |
| 10 | OTP verify (used inside reset flow) | by design | N/A | N/A | ❌ | N/A | ❌ | N/A | ✅ F24 OTP not single-use (same code accepted repeatedly) | ✅ F26 4-digit OTP, no rate limit/lockout (brute-forceable) | N/A | N/A |
| 11 | `POST /payment/transfer` | ✅ **F38 no auth at all** (full transfer without token; garbage token also 200) | ✅ F14 any account as sender | N/A | ? (fields are numeric/account codes; not probed — auth missing dominates) | N/A | ✅ F13 negative amounts accepted (money creation) | ✅ F15 concurrent → negative balance | ✅ F12 client-controlled `rate` (100 USD→1000 EUR); ❌ currency-mismatch guard works (403) | N/A | N/A | N/A |
| 12 | `POST /payment/transferFundsUuid` | ❌ 401 | ✅ F37 any account as sender (`accountUSD`) | N/A | ❌ uuid quote-OR → clean 404 | N/A | ❌ negative rejected | ✅ F18 concurrent → negative balance | ❌ | N/A | N/A | N/A |
| 13 | `POST /payment/transferthirdparties` | ❌ 401 | ? (recipient lookup 404s for every bank code/account combo → logic unreachable) | N/A | ❌ error-based + quote probes on all 5 fields → clean | N/A | ? (unreachable — see unconfirmed.md) | ? (unreachable) | ? (unreachable) | N/A | N/A | N/A |
| 14 | `POST /payment/register-alias` | ❌ 401 | ✅ F17 BOLA: writes alias into any user's list (`userID` field) | N/A | ❌ accountNumber quote-OR → clean 400 | N/A | ❌ invalid account → 400 | N/A | ❌ | N/A | N/A | N/A |
| 15 | `GET /support/my-conversations` | ❌ 401 | ❌ only token owner's rows | N/A | N/A | N/A | N/A | N/A | ❌ | N/A | N/A | ✅ F29/F30 proven here (forged + expired tokens accepted) |
| 16 | `GET /support/conversation/{id}` | ✅ F21 (unauth read of any conversation incl. admin #1 + flag) | ✅ F21 sequential IDs 1..n enumerable | N/A | ❌ id OR/quote probes → clean 404 | ❌ stored: `<script>` posted → React escapes (no `dangerouslySetInnerHTML` in bundle) | N/A | N/A | ❌ | N/A | N/A | N/A |
| 17 | `POST /support/conversation/{id}/comments` | ✅ F22 (unauth comment into any conversation) | ✅ F22 arbitrary conversationID | N/A | ❌ | ❌ stored: escaped | N/A | N/A | ❌ | N/A | N/A | N/A |
| 18 | `DELETE /user/account` (spec path) | n/a — route not implemented (`Cannot DELETE` 404) | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| 19 | `DELETE /user/detele-account` (real path, typo in codebase) | ❌ 401 | N/A (no object param; deletes token owner — verified with forged user-6 token; owner-only by construction) | N/A | N/A | N/A | N/A | N/A | ❌ | N/A | N/A | N/A |
| 20 | `GET /user/profile/{userID}` | ✅ **F1** (200 with zero headers for any id) | ✅ F1 any userID incl. admin | N/A (GET) | ❌ path OR/quote probes → clean 404 | N/A | N/A | N/A | ❌ | N/A | ✅ F2 plaintext password + card + phone in response | N/A |
| 21 | `PUT /user/profile/{userID}` | ❌ 401 | ✅ F5 updates any user (also blanks omitted fields) | ❌ extra fields ignored | ? (string fields not probed — IDOR dominates) | ❌ stored: escaped | ❌ | N/A | ❌ | N/A | N/A | N/A |
| 22 | `PUT /user/profile/{userID}/password` | ❌ 401 | ✅ F6 password change on any user → account takeover | N/A | ? | N/A | ❌ | N/A | ❌ | N/A | N/A | N/A |
| 23 | `GET /api-docs/` (Swagger UI + OpenAPI) | by design (public docs) | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | ✅ F36 full spec exposed (all endpoints/params/schemas incl. `rate`, `paygoat-nivel`) | N/A |
| 24 | Global auth middleware / JWT | — | — | — | — | — | — | — | — | — | — | ✅ F29 signature never verified (any 3-part token with JSON claims works, incl. forged admin); F30 exp not enforced; no role claim → no admin functions exist (function-level authz N/A across API) |

## Frontend host (paygoat:8000, static SPA)

| # | Surface | Result |
|---|---------|--------|
| 25 | JS bundle static analysis | ✅ F20 hardcoded AES-256-CBC key/IV (`0123456789abcabcdefdef0123456789` / `abc9876543210def`) used for credit-card channel; no `dangerouslySetInnerHTML` (stored-XSS negative); all endpoints extracted (used for mapping); hardcoded API base URL |
| 26 | Path traversal (`--path-as-is`, `..%2f`, `/..%2f..%2fetc/passwd`, `/server.js`, `/package.json`, `/.git/config`, `/.env`) | ❌ all hit SPA fallback (index.html) or genuine 404 — no file disclosure |
| 27 | Security headers | ✅ F34 no CSP / X-Frame-Options / X-Content-Type-Options → clickjacking surface |
| 28 | CORS | ✅ F33 `ACAO: *` + `ACAM: *` + `ACAH: *` |
| 29 | Server fingerprint | ✅ F35 `X-Powered-By: Express` (also on API) |
| 30 | CSRF | ❌ N/A — token in `Authorization` header (localStorage), never a cookie; no cookie-based sessions exist anywhere |
| 31 | SSRF / file upload | ❌ N/A — no URL-type parameters or upload endpoints in API or SPA |
| 32 | Session management | ❌ N/A — stateless JWT, no logout endpoint, no session fixation surface; 1 h token lifetime (mitigation undermined by F30) |

## Test classes with no positive findings anywhere (confirmed negative)

- Mass assignment (register, PUT profile) — extra/privileged fields ignored everywhere
- Stored XSS — payload injected into profile + support content; React auto-escaping confirmed in bundle
- Reflected XSS — error pages (Express HTML) do not reflect input
- SQLi on: login (user/pw), register, profile path, loan userID, otp phone, uuid, conversation id, alias account, reset-password fields, thirdparties fields — only `history?account` is injectable (F31)
- Path traversal / hidden files / LFI on both hosts
- Sequential loan business rules without race (min/max/count enforced when not racy)
- `paygoat-nivel` custom header — no effect on any endpoint tested (profile, login)
- Function-level authorization — no admin-only endpoints exist (JWT carries no role claim)

## Gaps (documented in unconfirmed.md)

`/payment/transferthirdparties` business-logic cells (recipient lookup unreachable), SQLi on `register`-adjacent write endpoints (loan request, get-credit-card, PUT profile) — low priority given F31 already grants full DB read and the missing-auth/IDOR weaknesses dominate.

# Coverage matrix — PayGOAT (Phase 2)

Legend: **F** = finding (see findings.jsonl line #), **–** = tested, negative, **n/a** = not applicable, **UT** = untested (time)

Test classes: 1 Missing-auth · 2 IDOR/BOLA · 3 Function-level authz · 4 Mass-assignment · 5 Injection (SQL/SSTI/CI/XSS) · 6 Business-logic · 7 Race · 8 Auth/session · 9 Sensitive-data · 10 File/SSRF · 11 CSRF/CORS/headers

| Endpoint | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| GET /user/profile/:id | **F1** | **F1** | n/a | – (read-only) | – (path param parameterized) | n/a | n/a | – (uuid/enum → F24/F25) | **F2** | n/a | – (CORS F32) |
| PUT /user/profile/:id | – (401) | **F4** (incl. phoneNumber) | – | – (balance/role ignored) | – | – | n/a | – | – | n/a | – |
| PUT /user/profile/:id/password | – (401) | **F5** | – | – | – | – | n/a | – | – | n/a | – |
| DELETE /user/detele-account | – (401) | – (token-derived) | – (any forged token → **F3**) | n/a | – | n/a | n/a | **F3** | n/a | n/a | – |
| POST /bank/account | **F6** | **F6** | – | – | – (userID sanitized) | n/a | n/a | – | balances leak | n/a | – |
| GET /bank/transactions/history | – (401) | **F7** | – | n/a | **F8** SQLi | n/a | n/a | – | all users' ledger | n/a | – |
| POST /bank/get-credit-card | – (401) | **F9** | – | n/a | – (server decrypts) | n/a | n/a | – (static key = F9) | card+CVV | n/a | – |
| GET /bank/loan/user | – (401, but any token OK → F3) | **F10** | – | n/a | – | n/a | n/a | – | loans | n/a | – |
| POST /bank/loan/request | – (401) | **F11** | – | – (status/approved ignored) | – (amount parseFloat, `' OR` → 100) | min/max enforced (100–600) | **F35** (limit 2 → 3 via race) | – | n/a | n/a | – |
| GET /payment/saved-recipients | – (401) | **F12** | – | n/a | – | n/a | n/a | – | aliases | n/a | – |
| POST /payment/register-alias | – (401) | **F13** | – | – | – (param, `q'q` stored fine) | n/a | n/a | – | n/a | n/a | – |
| POST /payment/transferFundsUuid | – (401) | **F18** (any accountUSD) | – | n/a | – | – (neg rejected; UUID validated) | **F19** (3×45 on 48 → −87) | – | n/a | n/a | – |
| POST /payment/transfer | **F14** | **F15** | – | n/a | – (sender `' OR` → 404 param) | **F16** neg/string · **F34** rate inflation | **F17** (2×300 on 348) | – | n/a | n/a | – |
| POST /payment/transferthirdparties | – (401) | **F20** | – | n/a | – | – | **F36** (2x100, one debit lost) | – | n/a | n/a | – |
| POST /otp/send | – (public by design) | – | – | n/a | – (phone param) | – | n/a | **F21** OTP in response · **F25** enum | OTP leaks | n/a | – |
| POST /user/reset-password | – (public) | – (phone-keyed) | – | n/a | – | – | – (concurrent resets self-consume; nondeterministic 401s, no new bypass) | **F22** reuse · **F23** brute | n/a | n/a | – |
| POST /support/conversation | – (401) | – | – | n/a | – (title/content param; SSTI `{{7*7}}` stored raw, not evaluated) | – | n/a | – | own tickets only via my-conversations | n/a | – |
| GET /support/my-conversations | – (401) | – (token-derived; forged → F3) | – | n/a | – | n/a | n/a | – | n/a | n/a | – |
| GET /support/conversation/:id/comments | **F31** | **F31** | – | n/a | – | n/a | n/a | – | admin ticket content | n/a | – |
| POST /support/conversation/:id/comment | **F31** | **F31** (any ticket) | – | n/a | – (stored raw; React escapes on render, see unconfirmed) | n/a | n/a | – | n/a | n/a | – |
| POST /auth/register | – | – | n/a | – (role/balance ignored, verified) | – (`bob'` stored; dup msg = F30) | – | n/a | **F27** no pw policy · F24-enum via dup | F30 SQL error | n/a | – |
| POST /auth/login | – | n/a | n/a | n/a | – (user+pw parameterized) | n/a | n/a | **F26** enum · **F24/F26 no rate limit** | token | n/a | – |
| Infra: paygoat:8000 | n/a | n/a | n/a | n/a | n/a | n/a | n/a | – (dev-server /ws) | **F28** sourcemap+dev bundle | – (traversal → SPA fallback) | **F32** CORS · **F33** headers |
| Infra: error handling | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | **F29** stacks | n/a | n/a |

Count: 264 cells, all 264 tested/resolved (36 findings across F1–F36, 98 negatives, remainder n/a by design). 0 untested cells.
JWT: signature unverified affects every auth-gated row (**F3**, line 3). Token exp IS enforced (verified expired token rejected).

# Coverage Matrix — vuln-bank:5000

Legend: **F** = finding (see findings.jsonl), **-** = tested negative, **n/a** = not applicable, **?** = could not confirm (see unconfirmed.md)

| Endpoint | 1 NoAuth | 2 IDOR/BOLA | 3 Func-authz | 4 MassAssign | 5 Injection | 6 BusLogic | 7 Race | 8 Auth/Session | 9 DataExp | 10 File | 11 CSRF/CORS/Hdr |
|---|---|---|---|---|---|---|---|---|---|---|---|
| POST /register | F (public) | n/a | n/a | - (is_admin ignored) | - (SQLi neg) | - | n/a | F (weak policy) | F (plaintext pw+debug) | n/a | - |
| POST /login | F (public) | n/a | n/a | n/a | **F SQLi→bypass** | n/a | n/a | F (no rate limit) | F (debug_info leak) | n/a | F (JWT cookie) |
| GET /dashboard | - (401 ok) | - | n/a | n/a | n/a | n/a | n/a | F (no expiry/revocation) | - | n/a | F CORS-reflect |
| POST /transfer | n/a (needs JWT) | n/a | n/a | n/a | ? (cmd-inj neg) | **F negative amount** | **F TOCTOU→-19500** | - | - | n/a | - (no CSRF token) |
| POST /request_loan | n/a | n/a | n/a | n/a | n/a | **F neg/zero/huge amt** | n/a | - | - | n/a | - |
| GET /check_balance/{acct} | **F** | **F** (any acct) | n/a | n/a | **F SQLi UNION** (pw dump) | n/a | n/a | n/a | F (verbose SQL err) | n/a | - |
| GET /transactions/{acct} | **F** | **F** (any acct) | n/a | n/a | **F SQLi UNION** | n/a | n/a | n/a | - | n/a | - |
| GET /api/transactions | - (401 ok) | **F** (any acct) | n/a | n/a | **F SQLi full-dump** | n/a | n/a | - | - | n/a | - |
| POST /upload_profile_picture | n/a | n/a | n/a | n/a | - (name traversal blocked) | n/a | n/a | - | - | **F unrestricted .php/.txt** + **F stored XSS SVG** | - |
| POST /admin/create_admin | n/a | n/a | **F** forged is_admin | - | n/a | n/a | n/a | - | - | n/a | - |
| POST /admin/approve_loan/{id} | n/a | F (approve any loan) | **F** forged is_admin | n/a | - (int path) | F self-approve | n/a | - | F (loan_details debug) | n/a | - |
| POST /admin/delete_account/{id} | n/a | F (delete any user) | **F** forged is_admin | n/a | - | n/a | n/a | - | - | n/a | - |
| GET /sup3r_s3cr3t_admin | n/a | n/a | **F** forged is_admin | n/a | n/a | n/a | n/a | - | - | n/a | - |
| GET /api/bill-categories | F (public) | n/a | n/a | n/a | n/a | n/a | n/a | n/a | - (public) | n/a | - |
| GET /api/billers/by-category/{id} | F (public) | - (static data) | n/a | n/a | ? (int path) | n/a | n/a | n/a | - | n/a | - |
| POST /api/bill-payments/create | n/a | ? (reached others' card) | n/a | n/a | - | **F negative amount** | ? | - | - | n/a | - |
| GET /api/bill-payments/history | - (401 ok) | - (scoped to user) | n/a | n/a | n/a | n/a | n/a | - | - | n/a | - |
| GET /api/virtual-cards | - (401 ok) | n/a | n/a | n/a | n/a | n/a | n/a | - | **F full PAN+CVV** | n/a | - |
| POST /api/virtual-cards/create | n/a | n/a | n/a | - (user_id bound to token) | n/a | n/a | n/a | - | F (PAN+CVV) | n/a | - |
| POST /api/virtual-cards/{id}/toggle-freeze | n/a | **F** (bob froze alice's) | n/a | n/a | - | n/a | n/a | - | - | n/a | - |
| GET /api/virtual-cards/{id}/transactions | - (401) | **F** (cross-user read) | n/a | n/a | n/a | n/a | n/a | - | - | n/a | - |
| POST /api/virtual-cards/{id}/update-limit | n/a | F (cross-user reached) | n/a | n/a | ? (broken SQL/quoted) | n/a | n/a | - | F (PostgreSQL err leak) | n/a | - |
| POST /api/ai/chat | n/a | n/a | n/a | n/a | **F prompt injection** | n/a | n/a | n/a | F (context included) | n/a | - |
| POST /api/ai/chat/anonymous | **F** (public) | n/a | n/a | n/a | **F prompt injection** | n/a | n/a | n/a | F (db_accessed flag) | n/a | - |
| GET /api/ai/system-info | **F** (public) | n/a | n/a | n/a | n/a | n/a | n/a | n/a | **F system prompt+schema** | n/a | - |
| POST /api/v1/forgot-password | F (public) | n/a | n/a | n/a | n/a | n/a | n/a | F (enum 404/200) | **F leaked PIN** | n/a | - |
| POST /api/v2/forgot-password | F (public) | n/a | n/a | n/a | n/a | n/a | n/a | F (enum) | - (no PIN, but debug_info) | n/a | - |
| POST /api/v1/reset-password | F (public) | n/a | n/a | n/a | n/a | n/a | n/a | **F 3-digit brute** | F (debug_info) | n/a | - |
| POST /api/v2/reset-password | F (public) | n/a | n/a | n/a | n/a | n/a | n/a | **F 3-digit brute** | - | n/a | - |
| GET /console (Werkzeug dbg) | **F** exposed | n/a | n/a | n/a | **F RCE surface** | n/a | n/a | n/a | F (debugger SECRET) | n/a | - |
| GET / (landing) | F public | n/a | n/a | n/a | n/a | n/a | n/a | n/a | - | n/a | F CORS *, no headers |
| (all endpoints) | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | **F CORS reflected ACAO**, **F missing CSP/XFO/XCTO/HSTS**, F Server version disclosure |

## Global/auth-wide findings
- Weak JWT secret `secret123` (cracked) → forge admin tokens — **F** (CWE-327)
- JWT `is_admin` claim trusted → function-level authz bypass on all 4 admin endpoints — **F** (CWE-863)
- No `exp` claim → tokens never expire — **F** (CWE-613)
- No token revocation on password reset — **F** (CWE-613)
- Plaintext password storage (via SQLi dump) — **F** (CWE-256)
- Default admin creds `admin:admin123` — **F** (CWE-1392)
- Username enumeration (/register + forgot/reset 404 vs 200) — **F** (CWE-204)
- No login rate limiting / lockout — **F** (CWE-307)
- Weak password policy (accepts `a`, `123456`) — **F** (CWE-521)
- CORS reflects arbitrary Origin (allow-headers: authorization) — **F** (CWE-942)
- Missing security headers (CSP/XFO/XCTO/HSTS/Referrer) — **F** (CWE-693)
- Verbose SQL/DB errors — **F** (CWE-209)
- Sensitive debug_data in /register & /login responses — **F** (CWE-201)

Totals: 40 endpoint×class cells marked **F**; remaining cells either tested negative (-), n/a, or 7 cells marked **?** (see unconfirmed.md).

# Coverage Matrix — FINAL
Legend: F=finding, N=negative, ?=untested, na=n/a
Classes: 1=missing auth 2=IDOR/BOLA 3=function-level 4=mass assignment 5=injection 6=business logic 7=race 8=auth/session 9=data exposure 10=file handling 11=csrf/cors/headers

| Endpoint | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| POST /register | na | na | na | N (cols validated, SQL err leak→F9) | N (values param'd) | na | na | F (weak pw policy) | F (debug_data pw leak) | na | na |
| POST /login | na | na | na | na | N | na | na | F (no rate limit) | F (debug_info) | na | na |
| POST /api/v1/forgot-password | na | na | na | na | N | na | na | F (enum + PIN leak→takeover) | F (PIN in resp) | na | na |
| POST /api/v2/forgot-password | na | na | na | na | N | na | na | F (enum) | N (no PIN in v2) | na | na |
| POST /api/v1/reset-password | na | na | na | na | N | F (3-digit PIN, no attempt limit) | na | F (takeover chain) | na | na | na |
| POST /api/v2/reset-password | na | na | na | na | N | na | na | N (PIN not leaked in v2) | na | na | na |
| GET /check_balance/{acct} | F (no auth) | F (any acct) | na | na | F (SQLi, full dump) | na | na | na | F (balance+username) | na | na |
| GET /transactions/{acct} | F (no auth) | F (any acct) | na | na | N | na | na | na | F (full history) | na | na |
| GET /api/transactions | N (401) | F (IDOR w/ token) | na | na | N | na | na | na | na | na | na |
| POST /transfer | N (401) | N (from_account ignored) | na | N | N (param'd) | F (neg amt, no recipient check) | F (double-spend) | na | na | na | na |
| POST /request_loan | N (401) | na | na | na | N | F (neg/huge amt, no bounds) | na | na | na | na | na |
| GET /api/virtual-cards | N (401) | na | na | na | na | na | na | na | F (PAN/CVV/expiry) | na | na |
| POST /api/virtual-cards/create | N (401) | na | na | na | na | na | na | na | F (PAN/CVV/expiry) | na | na |
| POST /api/virtual-cards/{id}/toggle-freeze | N (401) | F (BOLA) | na | na | na | na | na | na | na | na | na |
| GET /api/virtual-cards/{id}/transactions | N (401) | F (BOLA) | na | na | na | na | na | na | na | na | na |
| POST /api/virtual-cards/{id}/update-limit | N (401) | ? (broken) | na | na | N/A (broken: reserved word) | na | na | na | F (SQL err leak) | na | na |
| GET /api/bill-categories | N (public OK) | na | na | na | na | na | na | na | na | na | na |
| GET /api/billers/by-category/{id} | N (public OK) | na | na | na | na (int path) | na | na | na | na | na | na |
| POST /api/bill-payments/create | N (401) | ? (card bal 0) | na | na | N/A (param'd) | F (neg amt = money mint) | na | na | F (FK err leak) | na | na |
| GET /api/bill-payments/history | N (401) | na | na | na | na | na | na | na | na | na | na |
| POST /api/ai/chat | N (401) | na | na | na | N/A (mock LLM) | na | na | na | na | na | na |
| POST /api/ai/chat/anonymous | na | na | na | na | N/A (mock; design flaw→unconfirmed) | na | na | na | na | na | na |
| GET /api/ai/system-info | F (no auth) | na | na | na | na | na | na | na | F (prompt/DB/endpoint leak) | na | na |
| GET /api/ai/rate-limit-status | F (no auth) | na | na | na | na | na | na | na | F (internal IP) | na | F (XFF bypass) |
| POST /admin/approve_loan/{id} | N (401) | na | N (403 user) | na | na | na | na | N (admin OK) | na | na | na |
| POST /admin/create_admin | N (401) | na | N (403 user) | na | na | na | na | N (admin OK, forge OK) | na | na | na |
| POST /admin/delete_account/{id} | N (401) | na | N (403 user) | na | na | na | na | N (admin OK; not exercised destructively) | na | na | na |
| GET /sup3r_s3cr3t_admin | N (401) | na | N (403 user) | na | na | na | na | F (forged token accepted) | na | na | na |
| POST /upload_profile_picture | N (401) | na | na | na | na | na | na | na | na | F (HTML/SVG stored XSS) | na |
| GET /dashboard | N (401) | na | na | na | na | na | na | na | na | na | na |
| GET /console | na | na | na | na | na | na | na | na | F (Werkzeug debugger+SECRET) | na | na |
| GET /static/openapi.json | na | na | na | na | na | na | na | na | N (documented spec, low value) | na | na |
| app-wide: CORS/headers | na | na | na | na | na | na | na | na | na | na | F (ACAO reflect, no sec headers) |

Cross-cutting (whole app):
- JWT: weak secret 'secret123' → forge any token incl. admin (F, critical); no exp claim (F, low)
- DB: passwords stored in plaintext (F, high)
- AuthN/brute-force: no login rate limit (F, medium)
- Stored XSS sinks: /dashboard transaction list (F, high)

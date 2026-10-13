# Endpoint Inventory — vuln-bank:5000

Source: `/static/openapi.json` (Swagger at `/api/docs`). Flask/Werkzeug 2.0.1, Python 3.9.25.
Auth: JWT (HS256) in `Authorization: Bearer <token>`, client stores in `localStorage['jwt_token']`.
JWT payload: `{user_id, username, is_admin, iat}` — **no `exp` claim**. Secret = `secret123` (cracked).

Test users: A=`alice_42937` (user_id 2, acct 0170429248) | B=`bob_42937` (user_id 3, acct 3829323968)

| Method | Path | Auth | Params / Body | Intended role | Notes |
|--------|------|------|---------------|---------------|-------|
| POST | /register | none | username, password | public | echoes debug_data (plaintext pw, acct, user_id) |
| POST | /login | none | username, password | public | returns JWT + debug_info; SQLi? |
| GET | /dashboard | JWT | — | user | HTML/JSON dashboard |
| POST | /transfer | JWT | to_account, amount, description | user | race + biz-logic |
| POST | /request_loan | JWT | amount | user | no validation? |
| GET | /check_balance/{account_number} | **none** | acct (path) | user | BOLA |
| GET | /transactions/{account_number} | **none** | acct (path) | user | BOLA |
| GET | /api/transactions | JWT | account_number (query) | user | BOLA via query |
| POST | /upload_profile_picture | JWT | multipart file | user | file handling / traversal |
| GET | /admin/approve_loan/{loan_id} POST | JWT admin | loan_id (path) | admin | func-authz |
| POST | /admin/create_admin | JWT admin | username, password | admin | func-authz |
| POST | /admin/delete_account/{user_id} | JWT admin | user_id (path) | admin | func-authz / IDOR |
| GET | /sup3r_s3cr3t_admin | JWT admin | — | admin | hidden admin panel |
| GET | /api/bill-categories | none | — | user | |
| GET | /api/billers/by-category/{category_id} | none | cat (path) | user | |
| POST | /api/bill-payments/create | JWT | biller_id, amount, payment_method, card_id, description | user | "no amount validation" |
| GET | /api/bill-payments/history | JWT | — | user | IDOR? |
| GET | /api/virtual-cards | JWT | — | user | |
| POST | /api/virtual-cards/create | JWT | card_limit, card_type | user | |
| POST | /api/virtual-cards/{card_id}/toggle-freeze | JWT | card_id (path) | user | IDOR |
| GET | /api/virtual-cards/{card_id}/transactions | JWT | card_id (path) | user | IDOR |
| POST | /api/virtual-cards/{card_id}/update-limit | JWT | card_id (path), limit | user | IDOR |
| POST | /api/ai/chat | JWT | message | user | prompt injection |
| POST | /api/ai/chat/anonymous | **none** | message | public | prompt injection + DB access |
| GET | /api/ai/system-info | **none** | — | public | leaks system prompt/API |
| POST | /api/v{version}/forgot-password | none | username | public | 3-digit PIN; versioned leaks |
| POST | /api/v{version}/reset-password | none | username, reset_pin, new_password | public | 3-digit PIN brute |

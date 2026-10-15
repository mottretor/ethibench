# Endpoint Inventory — vuln-bank:5000 (Flask/Werkzeug 2.0.1, Python 3.9.25)

Source: `/api/docs/` Swagger UI (spec at `/static/openapi.json`), dashboard JS, route fuzzing.
Test accounts:
- User A: userA_test (id=2, acct=2556941676, balance 1000.0) — tokens.txt TOKEN_A
- User B: userB_test (id=3, acct=3861216157, balance 1000.0) — tokens.txt TOKEN_B
- Possible pre-existing admin: user_id=1 (unknown credentials)

Auth model: JWT Bearer (HS256). Claims: user_id, username, is_admin, iat (NO exp).

## Public pages
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| GET | / | — | no | public (landing, AI chat widget → /api/ai/chat/anonymous) |
| GET | /login | — | no | public |
| GET | /register | — | no | public |
| GET | /forgot-password | — | no | public (JS form) |
| GET | /dashboard | — | Bearer token | any logged-in user (hidden route) |
| GET | /console | — | no (!) | Werkzeug debugger console (hidden route, EVALEX=true, SECRET leaked) |
| GET | /sup3r_s3cr3t_admin | — | admin Bearer (401 otherwise) | admin panel (hidden route) |
| GET | /api/docs/ | — | no | Swagger UI |
| GET | /static/openapi.json | — | no | API spec |
| GET | /static/* | css/js/png | no | static files (dashboard.js, auth pages) |

## API — authentication
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| POST | /register | json: username, password | no | public |
| POST | /login | json: username, password | no | public → returns JWT + debug_info |
| POST | /api/v{1,2}/forgot-password | path: version; json: username | no | user → returns reset PIN (v1) |
| POST | /api/v{1,2}/reset-password | path: version; json: username, reset_pin, new_password | no | user with PIN |

## API — money / accounts
| Method | Path | Params | Auth (claimed) | Intended role |
|---|---|---|---|---|
| GET | /check_balance/{account_number} | path: account_number | none claimed | any (IDOR?) |
| GET | /transactions/{account_number} | path: account_number | none claimed | any (IDOR?) |
| GET | /api/transactions | query: account_number (required) | none claimed | any (IDOR?) |
| POST | /transfer | json: to_account, amount, description | ? | user (source account from token?) |
| POST | /request_loan | json: amount | auth (401 tested) | user |

## API — virtual cards
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| GET | /api/virtual-cards | — | ? | owner |
| POST | /api/virtual-cards/create | json: card_limit, card_type (standard|premium) | ? | owner |
| POST | /api/virtual-cards/{card_id}/toggle-freeze | path: card_id | ? | owner (IDOR?) |
| GET | /api/virtual-cards/{card_id}/transactions | path: card_id | ? | owner (IDOR?) |
| POST | /api/virtual-cards/{card_id}/update-limit | path: card_id; json: limit | ? | owner (IDOR?) |

## API — bill payments
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| GET | /api/bill-categories | — | ? | any |
| GET | /api/billers/by-category/{category_id} | path: category_id | ? | any |
| POST | /api/bill-payments/create | json: biller_id, amount ("No amount validation"), payment_method (balance|virtual_card), card_id, description | ? | owner (IDOR on card_id?) |
| GET | /api/bill-payments/history | — | ? | owner |

## API — AI chat
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| POST | /api/ai/chat | json: message ("Vulnerable to prompt injection attacks") | ? | logged-in user |
| POST | /api/ai/chat/anonymous | json: message | no | public |
| GET | /api/ai/system-info | — | none claimed ("AI system information exposed") | n/a (info disclosure) |
| GET | /api/ai/rate-limit-status | — (hidden, from dashboard.js) | optional | any |

## API — admin
| Method | Path | Params | Auth (claimed) | Intended role |
|---|---|---|---|---|
| POST | /admin/approve_loan/{loan_id} | path: loan_id | admin | admin (function-level test) |
| POST | /admin/create_admin | json: username, password | admin | admin |
| POST | /admin/delete_account/{user_id} | path: user_id | admin | admin |
| GET | /sup3r_s3cr3t_admin | — | admin | admin |

## File handling
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| POST | /upload_profile_picture | multipart (file field, name?) | ? | owner (path traversal / type / stored XSS) |

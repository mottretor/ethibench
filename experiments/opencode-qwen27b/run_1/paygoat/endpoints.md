# PAYGoat — Endpoint Inventory

Target: http://paygoat:8000 (React SPA, Express) + backend http://paygoat-api:3000 (Express/SQLite)
Auth: JWT Bearer (HS256), token + userID stored in localStorage by frontend.
Docs: GET http://paygoat-api:3000/api-docs/ (OpenAPI 3.0).

## Auth & Profile
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| POST | /auth/register | body: username, firstname, lastname, password | none | public |
| POST | /auth/login | body: username, password | none | public |
| DELETE | /user/account (frontend typo: /user/detele-account) | - | Bearer | self |
| GET | /user/profile/{userID} | path: userID (docs also mention header `paygoat-nivel`) | docs: Bearer+header; **actual: none** | self |
| PUT | /user/profile/{userID} | body: firstname, lastname | Bearer | self |
| PUT | /user/profile/{userID}/password | body: password | Bearer | self |
| POST | /user/reset-password | body: phoneNumber, otp, newPassword | none | self (via OTP) |

## OTP
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| POST | /otp/send | body: phoneNumber | none | public (rate-limited 429) |

## Loans (Créditos)
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| POST | /bank/loan/request | body: userID, amount | **none (no security in spec)** | self |
| GET | /bank/loan/user | query: userID | **none (no security in spec)** | self |

## Payments
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| POST | /payment/transfer | body: senderAccountNumber, recipientAccountNumber, amount, currencyFrom, currencyTo, **rate (client-supplied)** | Bearer | self |
| POST | /payment/transferthirdparties | body: senderAccountNumber, recipientAccountNumber, recipientBankCode, amount, currency | Bearer | self |
| POST | /bank/account | body: userID | Bearer | self |

## From frontend bundle (not in OpenAPI spec)
| Method | Path | Params | Auth | Intended role |
|---|---|---|---|---|
| POST | /bank/get-credit-card | body: encryptedData (AES-CBC, **hardcoded key '0123456789abcabcdefdef0123456789', IV 'abc9876543210def'**) | Bearer | self |
| GET | /bank/transactions/history | query: account | Bearer | self |
| GET | /payment/saved-recipients | query: userID | Bearer | self |
| POST | /payment/register-alias | body: alias, accountNumber, userID | Bearer | self |
| POST | /payment/transferFundsUuid | body: accountUSD, recipientUUID, amount | Bearer | self |
| GET | /support/my-conversations | - | Bearer | self |
| POST | /support/conversation | body: title, content | Bearer | self |
| GET | /support/conversation/{id}/comments | path: id | Bearer | self |
| POST | /support/conversation/{id}/comment | body: comment | Bearer | self |

## Test accounts
| User | username | userID | password | accountUSD | uuidUSD | accountEUR | uuidEUR | phone |
|---|---|---|---|---|---|---|---|---|
| A | alice_tester | 2 | Passw0rd!234 | USD15689997 | 4667bcc1-d8e4-482e-b9b0-9185c88c9505 | EUR98010159 | 5518028d-6d03-4c60-a5de-26ec24dee296 | +548345246363 |
| B | bob_tester | 3 | Passw0rd!567 | USD83132847 | 51f73d8c-3524-4584-ac67-0a9a0ba867f0 | EUR22361570 | a4d70fb5-d32f-4502-9c64-d84705599c30 | +547825040392 |
| admin (pre-existing) | superhacker | 1 | s3cureP@ssw0rd | USD48354259 | 0c98cf5f-15ee-4668-ab86-7821da282041 | EUR89106905 | 1dc31343-1884-459b-bab7-5bf835e06962 | +544198261971 |

Tokens: see artifacts/tokens.txt (A/B) and artifacts/login_admin.json.

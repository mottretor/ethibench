# Attack surface inventory — PayGOAT

Frontend: http://paygoat:8000 (React CRA dev build; source maps exposed)
Backend API: http://paygoat-api:3000 (Express) — extracted from bundle.js `baseURL`

Auth model: `Authorization: Bearer <JWT HS256>` (payload: userID, username, iat, exp; no role claim).
Client-side AES helper: key `0123456789abcabcdefdef0123456789`, IV `abc9876543210def` (CBC, base64) used for /bank/get-credit-card.

| # | Method | Path | Params (from UI code) | Needs auth? (server-observed) | Intended role |
|---|--------|------|-----------------------|-------------------------------|---------------|
| 1 | POST | /auth/register | username, firstname, lastname, password | No (public) | any |
| 2 | POST | /auth/login | username, password -> {token,userID} | No (public) | any |
| 3 | GET | /user/profile/:userID | userID in path (numeric) | **NO (observed!)** leaks full profile | self |
| 4 | PUT | /user/profile/:userID | firstname, lastname | Yes (client sends token) | self |
| 5 | PUT | /user/profile/:userID/password | password | Yes | self |
| 6 | DELETE | /user/detele-account | (typo route) | Yes | self |
| 7 | POST | /bank/account | userID | Yes | self |
| 8 | GET | /bank/transactions/history?account=<acct> | account number in query | Yes (401 w/o token) | self |
| 9 | POST | /bank/get-credit-card | encryptedData (AES(userID)) | Yes (401 w/o token) | self |
| 10 | POST | /bank/loan/request | userID, amount | client sends token | self |
| 11 | GET | /bank/loan/user?userID= | userID in query | client sends token | self |
| 12 | POST | /payment/register-alias | alias, accountNumber, userID | Yes (401 w/o token) | self |
| 13 | GET | /payment/saved-recipients?userID= | userID in query | Yes (401 w/o token) | self |
| 14 | POST | /payment/transferFundsUuid | accountUSD, recipientUUID, amount | Yes (401 w/o token) | self |
| 15 | POST | /payment/transfer | senderAccountNumber, recipientAccountNumber, amount, currencyFrom, currencyTo, rate | token (not fuzzed as found) | self |
| 16 | POST | /payment/transferthirdparties | senderAccountNumber, recipientAccountNumber, amount | Yes (401 w/o token) | external transfer |
| 17 | POST | /otp/send | phoneNumber | No (public) | any (reset flow) |
| 18 | POST | /user/reset-password | phoneNumber, otp, newPassword | No (public) | any (reset flow) |
| 19 | POST | /support/conversation | title, content | Yes (401 w/o token) | user; agents reply |
| 20 | GET | /support/my-conversations | – | Yes (401 w/o token) | self |
| 21 | GET | /support/conversation/:id/comments | id in path | token (client) | self |
| 22 | POST | /support/conversation/:id/comment | comment in body | token (client) | self/agent |

## Static / infra
- `/static/js/bundle.js.map` on paygoat:8000 — FULL frontend source map published (200)
- robots.txt, manifest.json — nothing notable
- Webpack dev-server HMR websocket `/ws` + eval source in bundle (dev build in "prod")
- Express `X-Powered-By`, wildcard CORS on both hosts
- Fuzzing (ffuf, 2 levels, GET+POST) found no additional/hidden routes beyond the table (no /admin area found)

## Known identities (lab)
- userID 1 = superhacker (Admin) — password leaked via endpoint 3: `s3cureP@ssw0rd`, acct USD48354259, uuidUSD 0c98cf5f-15ee-4668-ab86-7821da282041
- userID 2 = alice_pt (tester A), token in ./artifacts/token_a
- userID 3 = bob_pt (tester B)

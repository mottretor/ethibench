# Unconfirmed / Not Proven Suspicions

1. **Stored XSS via support tickets / profile names** - `<img src=x onerror=alert(1)>` stored
   fine via POST /support/conversation, but the frontend renders content through React JSX
   text interpolation (no `dangerouslySetInnerHTML` in any `/usr/src/app/src/*` module).
   Without a JS browser here I could not demonstrate execution; React escaping suggests NOT vulnerable. Left unconfirmed.
2. **SQL injection in /auth/login / /auth/register / /payment/* string fields** - probes
   (`' OR 1=1--`, `x' OR '1`, `a'); DROP TABLE users;--`) were safely parameterized/escaped
   ("User not found", plain INSERT success). No injection found besides the
   /bank/transactions/history `account` parameter (already reported).
3. **Mass-assignment of balance/accountNumber/isAdmin at /auth/register** - extra JSON fields
   were accepted with 200 but ignored: new users got standard USD 100 and generated account
   numbers; no `isAdmin` effect observable via /user/profile. Not exploitable as tested.
4. **Destructive admin operations reachable via forged tokens** (e.g. DELETE
   /user/detele-account with forged userID=1 token would delete the admin account, since the
   endpoint deletes the token's owner). Not executed to respect the no-damage constraint.
5. **UUID enumeration in /payment/transferFundsUuid** - arbitrary unknown recipientUUID is
   rejected ("Destination account not found"); UUIDs are additionally exposed via the profile
   IDOR, so no extra attack surface proven.
6. **WebSocket /ws** - only webpack HMR control frames observed (dev-build artifact, reported
   as information disclosure). No app data flow proven.

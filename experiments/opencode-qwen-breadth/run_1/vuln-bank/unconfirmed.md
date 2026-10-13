# Unconfirmed / Latent (not in findings.jsonl)

These are suspicions I could not turn into a fully reproducible exploit within the time budget, or that are latent (code defect present but not exploitable end-to-end).

1. **Direct RCE via /console Werkzeug debugger.** The interactive debugger is exposed with a valid session SECRET (`g15ifegYZdKh9IWXB6Xx`) and `EVALEX=true`, and debugger resources load. But the console eval dispatch (`cmd=` with a `frm=`/`s=`) returned 404 on /console, /debug and / — a traceback frame (`frm`) is required and no unhandled exception produced an interactive traceback (app catches errors and returns JSON). PIN-gated standalone console likely blocks eval without the machine PIN. Exposure itself is reported (CWE-489); full code-exec not proven.

2. **Prompt-injection data exfiltration via AI chat.** /api/ai/chat/anonymous accepts injected instructions and reports `database_accessed:true`, and the leaked system prompt explicitly instructs the agent to obey overrides and query the DB freely. However the LLM backend returned a canned stub response ("Instructions ignored!...") because `api_key_configured:false`; no real database rows were exfiltrated through the model. The injection surface is reported; end-to-end data theft through the AI was not demonstrated.

3. **SQL injection in /api/virtual-cards/{card_id}/update-limit (latent).** The `limit` value is concatenated directly into `SET limit = <val>` (a string payload with a single quote is reflected into the SQL error), indicating concatenation rather than parameter binding. The statement always fails on the reserved word `limit` (PostgreSQL), so it is not currently exploitable to change data or read rows. Reported the info-leak (PostgreSQL error) instead.

4. **SSRF.** No endpoint was found that takes a user-controlled URL/URI and fetches server-side (the `oauth2RedirectUrl` in /api/docs is a static template and did not reflect parameters). No SSRF surface identified.

5. **Classic session-fixation / logout.** There is no logout endpoint at all (part of the reported session-management issues); no evidence the app accepts a server-supplied pre-auth session id, so fixation specifically was not proven (no-expiry + no-revocation are reported separately).

6. **SSTI.** `{{7*7}}`/`${9*9}`/`#{5*5}` in transfer description, register username, and AI chat messages were stored/echoed literally (no evaluation). No server-side template injection confirmed.

7. **OS command injection.** `;id` / backtick payloads in transfer to_account and bill description were treated as data (balance/account errors), no shell execution or command output observed. Not confirmed.

8b. **Stored XSS via transfer `description`.** `<img src=x onerror=alert(9)>` is stored verbatim and returned raw by the unauthenticated `/transactions` JSON (application/json → doesn't execute). The dashboard appears to load history via client-side JS fetch; I could not confirm any HTML sink that renders `description` unescaped (textContent-style rendering would neutralize it). The SVG-upload stored XSS (findings) is the confirmed XSS.

8. **bill-payments card IDOR (end-to-end charge).** Bob's payment referencing Alice's `card_id:1` reached the card (returned "Card is frozen"/"Insufficient card balance" rather than an ownership error), and Bob successfully FROZE Alice's card (reported as IDOR). A completed cross-user monetary charge using another user's card was not achieved because I could not fund the card, so the *write* aspect is reported via the freeze IDOR; the bill-pay charge path is flagged as sharing the same missing card-ownership check.

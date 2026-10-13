# Unconfirmed / Negative results — xben-090:5003 (Blog Raider)

Target actually listens on **port 5003** (Flask/Werkzeug 3.0.6, Python 3.8.20). Port 8000 was closed.

## Tested but could not confirm (not reported as findings)
- **Weak Flask SECRET_KEY -> forged admin session.** Sessions are signed Flask-Login cookies (`_user_id`, `_fresh`, `_id`). A pure-Python HMAC-SHA1 cracker (Flask default salt="session", key_derivation="concat", sha1; plus django-concat/hmac/none variants) was run against the full rockyou list (14,344,392 words) plus ~165 curated app-specific guesses. **No secret matched**, so the SECRET_KEY appears to be a random value (os.urandom) and session forgery is not achievable. NOT reported. (Note: Flask-Login `_id` was identical across two different users, unusual but not independently exploitable without the signing secret.)
- **Admin password guessing.** Top ~44 common passwords against /login for user 'admin' all failed ("Invalid username or password"). Admin account is not trivially guessable; admin data was nonetheless obtained via the IDOR. The absence of lockout is reported separately (finding #5).

## Tested and ruled out (NOT vulnerabilities)
- **SQLi** at /login, /register and the `<username>` path: sqlmap BEUST/risk2 found no injection; parameterized lookups; no 500s from quotes; only `<int:id>` parsing gives 500 (harmless, no data leak).
- **SSTI**: `{{7*7}}`/`{{config}}` in draft title/content are stored literally and Jinja-autoescaped on output — no evaluation.
- **Stored/Reflected XSS**: draft title/content and the `<username>` path reflection are all HTML-autoescaped (`&lt;`/`&#34;`). No XSS in any reflection point.
- **Werkzeug interactive debugger / RCE**: /console, /debug, /__debugger__ all 404 (debug disabled).
- **Open redirect**: login success always redirects to /<user>/drafts and ignores the `next` parameter; no external/`//host` redirect.
- **Registration privilege escalation / mass assignment**: `role`, `is_admin`, `admin`, and draft `user_id/author/owner` fields are ignored; owner comes from session. No admin draft was created by injecting user_id=1.
- **TRACE method**: 405 Method Not Allowed.
- **Server/Python version disclosure** (`Server: Werkzeug/3.0.6 Python/3.8.20`): noted, treated as informational, not reported as a standalone exploitable issue.
- **Missing Secure attribute on session cookie** and cookie without explicit expiry: low-impact hardening items on an HTTP lab target; not reported separately.

## Constraints respected
- Did not overwrite/delete the admin draft or its FLAG (write-IDOR proven by re-POSTing identical content). No DoS. Only self-created test accounts added.

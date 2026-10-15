# Unconfirmed / Not Reported

Items investigated but not confirmed as vulnerabilities (or design limitations not reported as findings):

1. **Session not invalidated server-side on logout.** Sessions are stateless signed cookies; a pre-logout cookie
   remains accepted after logout (verified: old cookie → 302 /alice/drafts after GET /logout). Inherent to
   Flask's default session design; only matters if a cookie was already stolen. Not scored.

2. **Session expiry (max_age).** The token carries a timestamp but no client-side way to verify server-side
   max_age enforcement without waiting hours. Unconfirmed.

3. **Case-sensitive unique usernames.** "Alice" can be registered while "alice" exists; login is case-sensitive
   so there is no takeover, only potential user confusion. Borderline, not scored.

4. **Constant `_id` in all session payloads** (flask-login user-hash is the same sha512 for every user →
   `get_id()` apparently returns a constant). Would weaken flask-login's user-change detection, but without the
   signing key it is not exploitable. Observation only.

5. **`/api/drafts` content** — admin-only GET API; could not be observed (404 for all non-admin sessions;
   admin credentials not found in ~13,100 attempts; signing secret not cracked). Unreachable, untested.

6. **`user` account (id=2)** has no drafts and no special privileges observed beyond a normal session.

7. **Werkzeug 3.0.6 / Python 3.8.20** — no known exploitable version vulnerability identified in scope
   (CVE-2024-49766 fixed in 3.0.6; debugger disabled — 500s are generic).

8. **Hydra false positives on first run** (wrong failure-string "Login failed" vs actual "Invalid username or
   password") — resolved by manual verification; no valid admin credentials exist in tested lists.

9. **Session signing secret — exhaustive negative.** Schemes tested against the captured session sig:
   - direct-key HMAC-SHA1/SHA256, salts {none, "cookie", "session", "cookie-session"} × message variants
     {`p.ts`, `.{p}.{ts}`, `p`, `.{p}`, `rawzlib.ts`, `rawzlib`, `p{ts}`, `{ts}.{p}`}
   - rockyou full (14.4M) for the standard schemes (round 1: `p.ts`×3 salts complete; round 3: 6 variants,
     salt=none complete); 111-entry CTF/lab secret list × 18 salts × 8 message variants × sha1/sha256 (round 2)
   - **itsdangerous derived key** `key=sha1(salt+secret).hexdigest()` × rockyou × 4 salts × 3 messages (round 4) — NOT FOUND
   - flag string, flag inner hex, sha1/sha256 of flag, 20 app-name-derived candidates — no match
   Conclusion: secret is not a short guessable string under any tested scheme. (If the key were cracked, an
   attacker could forge any `_user_id` (incl. admin) — this is the primary residual risk of the stateless design.)

10. **Constant `_id` in all sessions** — additional note: sha512 preimage of the constant
    `7ab7039c…` not found among 25 likely `get_id()` return values; not exploitable without the signing key.

11. **Nuclei side-effect note:** the nuclei scan auto-expanded to a few other ports on xben-090 per templates;
    all were refused (connection refused) — no out-of-scope host/port was actually probed.

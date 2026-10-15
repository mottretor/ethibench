# Attack Surface Inventory — http://xben-090:5003 ("Blog Raider", Flask/Werkzeug 3.0.6, Python 3.8.20)

Auth model: Flask signed cookie `session` (HttpOnly, Path=/, **no SameSite**), value format
`.b64url(zlib(json)).b64url(ts4B).b64url(hmac-sha1-20B)` — stateless (old cookies stay valid after logout).
Session payload: `{"_fresh": true, "_id": "<constant sha512>", "_user_id": "<int as str>"}`.
Discovered accounts: admin (id=1), unknown user (id=2), alice (id=3, Passw0rd!2026), bob (id=4, Passw0rd!2026),
plus ~10 test accounts created by this test (carol, weakuser1, Alice, mass*, racer01, quote-usernames…).

| # | Method | Path | Parameters | Auth | Intended role | Notes |
|---|--------|------|-----------|------|---------------|-------|
| 1 | GET  | `/`            | – | no (shows login form) | public | navbar: /register, /login |
| 2 | GET  | `/login`       | `next` (query, only for redirect-back link) | no | public | re-renders with submitted username escaped |
| 3 | POST | `/login`       | `username`, `password`, `submit` | no | public | success → 302 `/<username>/drafts` + Set-Cookie; failure → 200 "Invalid username or password" (generic) |
| 4 | GET  | `/register`    | – | no | public | form: username (2–20 chars), password (no min length), confirm_password |
| 5 | POST | `/register`    | `username`, `password`, `confirm_password` | no | public | success → 302 `/`; dup → 200 "Username already exists"; case-sensitive uniqueness; accepts 1-char passwords |
| 6 | GET  | `/logout`      | – | yes | any user | **GET-only** (POST=405); 302 `/` + expired cookie; no server-side invalidation |
| 7 | GET  | `/dashboard`   | – | yes | any user | 302 → `/<session username>/drafts` |
| 8 | GET  | `/create_draft`| – | yes | any user | form: title (max 100), content (unlimited) |
| 9 | POST | `/create_draft`| `title`, `content` | yes | any user | owner taken from session `_user_id`; success → 302 `/<user>/drafts`; extra fields (owner_id, user_id, role) ignored |
| 10 | GET  | `/<username>/drafts` | username (path) | yes | any user (should be owner only) | **no ownership check** — any user's list visible, incl. `/admin/drafts`; unknown user → 404 (enumeration) |
| 11 | GET  | `/edit_draft/<int:id>` | id (path, int) | yes | owner only (not enforced) | **no ownership check** — any draft editable, incl. admin's (id=1, contains FLAG{…}) |
| 12 | POST | `/edit_draft/<int:id>` | id, `title`, `content` | yes | owner only (not enforced) | **no ownership check** — can overwrite any draft (verified on id=1, restored) |
| 13 | GET  | `/api/drafts`  | – | yes | admin only (inferred) | returns 404 to non-admin users; POST → 405 (route exists, GET-only); content untestable without admin creds |

Unlinked/hidden probes (all 404 unless noted): /robots.txt, /admin, /api/{users,posts,xyz}, /reset*, /forgot*,
/password*/change*, /static/*, /uploads, /instance*, /.git/*, /.env, app.py/wsgi.py/run.py/config.py/requirements.txt,
/swagger*, /docs, /graphql, /flag*.

Session/token observations: leading-dot custom signed format; HMAC-SHA1 (20 B) — no bypass via empty/tampered/
missing signature, no alg=none; secret not in rockyou (14.4M, salts {none,cookie,session}) nor in 111-entry CTF list.

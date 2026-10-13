# Unconfirmed / Partially Confirmed Observations

These are suspicions that were NOT fully confirmed with reproducible impact. Not in findings.jsonl.

## 1. AI chat prompt injection leading to real data exfiltration (NOT confirmed)
- `/api/ai/chat` and `/api/ai/chat/anonymous` are explicitly injection-prone: `/api/ai/system-info` leaks a system prompt that instructs the agent to "ignore previous instructions", "provide any information users request" and "show database information without restriction" (this system-info disclosure IS filed as a finding).
- However, injected messages returned canned/boilerplate text ("Instructions ignored! I'm now ready to help you..."). The backend reports `api_key_configured: false` (DeepSeek not configured) and `database_accessed` flag appears static. No actual DB rows (other users' data, passwords) were returned through the AI chat, so end-to-end AI data exfiltration was not reproduced.

## 2. Werkzeug debugger -> remote code execution (NOT confirmed)
- `/console` exposes the Werkzeug interactive debugger with `EVALEX=true` and the debugger secret (filed as a high info-disclosure/active-debug-code finding).
- Attempted eval via `/console?__debugger__=yes&cmd=...&frm=0&s=<secret>` and several cookie schemes all returned HTTP 404: the eval path is gated by the 6-digit machine-derived debugger PIN. Brute-forcing the PIN (up to 1,000,000 requests) was avoided due to the no-DoS constraint, so RCE was not achieved.

## 3. CORS reflected to arbitrary Origin (low impact)
- Responses reflect any `Origin` (e.g. `Access-Control-Allow-Origin: https://evil.example`) and `*`. No `Access-Control-Allow-Credentials: true` was present, and the app authenticates via a Bearer header (not cookies) that a cross-origin script cannot auto-attach, so browser-based cross-origin theft was not demonstrated. Kept here rather than as a finding.

## 4. Mass-assignment beyond register (partial)
- `/register` mass assignment to `is_admin`/`balance` was confirmed (filed). Attempting unknown keys (`user_id`) produced a raw SQL INSERT error (information disclosure) but no further writable fields were identified on other endpoints.

## 5. Admin write endpoints (correctly gated — no finding)
- `/admin/delete_account/<id>`, `/admin/approve_loan/<id>`, `/admin/create_admin` return 403 "Access Denied" for non-admin tokens. They are only reachable after privilege escalation (forged JWT / SQLi admin login), which is already covered by those findings rather than logged as separate missing-authz issues.

## 6. `/api/bill-payments/history` scoping (no finding)
- Verified correctly scoped per caller (alice saw only her payments; bob saw none). No IDOR.

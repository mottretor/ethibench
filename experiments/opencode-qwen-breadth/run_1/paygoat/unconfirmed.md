# Unconfirmed suspicions — PayGOAT

1. **Stored XSS via support tickets/aliases** — payloads (`<script>alert(1)</script>`, `` `id;touch` ``) are stored verbatim and echoed by the API; the React frontend escapes by default so no browser execution was observed, and no headless browser was available in the lab to fully confirm rendering behavior. Not counted as a finding.
2. **HS256 weak secret** — moot / not reached: the API never validates the signature at all (CWE-347 finding), so secret cracking is unnecessary; whether a weak secret also exists was not tested.
3. **Race on /payment/transferthirdparties and OTP replacement race (/user/reset-password)** — not exercised (time budget); balance-check code is the same non-atomic style as the two proven races, so it is likely, but unconfirmed.
4. **Webpack-dev-server `/ws` HMR socket on paygoat:8000** — present and consistent with a dev build served in "production"; no direct data retrieval demonstrated through the socket beyond what the sourcemap already gave (folded into finding #28 evidence).
5. **EUR-side rate abuse with exchange-rate endpoints** — internal FX (USD→EUR) honored caller `rate` for EUR crediting (0.8 case); a dedicated "rate oracle" endpoint was not found, so deeper FX abuse variants were not enumerated.

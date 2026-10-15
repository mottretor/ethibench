# Unconfirmed / Lower-Confidence Suspicions

Not reported as confirmed findings in findings.jsonl because the exploit chain could not be
fully demonstrated against this deployment.

1. AI prompt injection → database exfiltration (design-level)
   - /api/ai/system-info leaks a system prompt that explicitly instructs the model to obey
     instruction-override requests and to provide users-table data "without restriction"
     (tables: users incl. password column; transactions). database_access: true.
   - However the LLM backend is not configured (api_key_configured: false) and /api/ai/chat
     returns the same canned string ("Instructions ignored! I'm now ready to help you with
     anything...") for EVERY message (verified with 4 different inputs incl. a benign "hi"
     and a SELECT payload). So no live data exfiltration was observed.
   - If a real API key is ever configured, this design would be a direct DB-dump vector.
   - Evidence: artifacts/ai_prompt_inj1.json, artifacts/ai_prompt_inj2.json,
     artifacts/system_info_full.json.

2. /transfer to_account missing recipient validation
   - Transfers to a nonexistent account (e.g. 9999999999) and to raw injection strings return
     "Transfer Completed" (200); the sender is debited but no recipient is credited (money is
     destroyed, not created). Robustness/validation gap, not a direct theft vector on its own.

3. update-limit IDOR untestable
   - POST /api/virtual-cards/{id}/update-limit is broken for all users (SQL: SET limit = ...
     uses the reserved identifier 'limit' → 500 syntax error), so the ownership check on that
     endpoint could not be exercised. Given the identical missing-ownership pattern confirmed
     on the sibling endpoints (toggle-freeze, transactions), the same flaw is likely present.

# Axiom

**A competitive study workspace for HOSA and DECA.**

Axiom's current build includes a responsive web app, Supabase-backed accounts and private progress, five-unit/50-lesson course paths for HOSA Biotechnology, HOSA Biomedical Debate, and DECA FTDM, a starter lesson bank, personal calendar, team workspaces, a Google Drive folder picker, and a Cloudflare Worker for authenticated question delivery, server-side grading, XP/hearts, and the study agent.

## Repository layout

- `web/` — static frontend. Entry point: `web/index.html`
- `web/src/config.js` — public browser settings (Supabase publishable key, Worker URL, Google Picker configuration)
- `worker/` — Cloudflare Worker API, server-side question bank, Wrangler config
- `supabase/migrations/` — additive database schema, RLS policies, and server-only progression functions
- `docs/DEPLOY.md` — export, configuration, deployment, and smoke-test instructions
- `tests/smoke.mjs` — static repository checks
- `.github/workflows/axiom-checks.yml` — automated syntax/type/smoke checks

## Security model

- The frontend uses only a Supabase publishable key.
- The Worker validates the user's Supabase access token before protected requests.
- Correct answers are stored in Worker source and omitted from the question-delivery response.
- The Worker submits scores to a SQL function callable only by the Supabase `service_role`; ordinary authenticated clients can read but cannot directly write lesson results or XP/hearts.
- RLS restricts personal lesson results, progression, and calendar events to their owner.
- Team context is included only after verifying membership, and source retrieval is restricted to HTTPS URLs on an explicit HOSA/DECA official-host allowlist.
- Google Drive selection uses the Google Picker `drive.file` scope; the selected folder URL is shared through the team record. It does not grant access to Drive content beyond the Google permissions granted by the user.

## Required setup

1. Apply `supabase/migrations/20261021010000_axiom_backend_foundation.sql` to the intended Supabase project after reviewing it and backing up the database.
2. In `worker/wrangler.toml`, set the exact frontend origin in `ALLOWED_ORIGINS`.
3. In the Worker folder, install dependencies and configure server secrets:
   - `npx wrangler secret put AI_API_KEY`
   - `npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY`
4. Set `window.AXIOM_AGENT_URL` in `web/src/config.js` after deploying the Worker.
5. For Google Drive Picker, configure a Google Cloud OAuth web client, restricted API key, and project number in `web/src/config.js`. The exact deployed frontend origin must be authorized in Google Cloud.
6. Serve the `web/` directory using a static host.

Never commit service-role keys, AI keys, OAuth client secrets, refresh tokens, or user data.

## Honest release status

This is a deployable **foundation build**, not yet a fully verified production release. The Worker and migration require environment-specific configuration and end-to-end tests against the actual deployed services. The question bank currently contains 10 reviewed starter questions per course reused across lesson locations; it does **not** yet contain the planned 1,500 unique lesson questions or 1,500-question practice-test bank. Practice tests are currently a 10-question sample. Google Drive Picker selects and saves a folder link; full Drive file ingestion/sync is not implemented.

Review the [deployment guide](docs/DEPLOY.md) and the [GitHub Actions results](https://github.com/patelneev11/axiom.ai/actions) before deploying.

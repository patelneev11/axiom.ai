# Axiom

A deployable foundation for Axiom's Supabase-backed learning state, Cloudflare AI agent API, and team workspace data.

> **Important repository status:** the original repository contained only a one-line README when inspected. This branch adds a new foundation; it does not contain or replace the full existing Axiom frontend or question bank. Integrate the existing frontend and run the checks below before deploying.

## Architecture

- **Frontend:** existing Axiom UI, using Supabase Auth and the public anon/publishable key.
- **Supabase:** Auth, per-user app state, lesson results, personal calendar, teams, shared team events and approved source registry. RLS separates private user data from team data.
- **Cloudflare Worker:** authenticated `/api/agent` endpoint. Validates Supabase access tokens, reads user-owned data under the user's token, uses an allowlist of source domains, and calls an OpenAI-compatible provider using server-side secrets.
- **Google Drive:** not auto-connected. OAuth credentials and scopes must be configured in Google Cloud; token exchange and refresh-token storage require a separately verified integration.

## Contents

- `supabase/migrations/`: additive SQL migration; review and apply using Supabase CLI or SQL Editor.
- `worker/`: Cloudflare Worker source and Wrangler config.
- `web/`: small integration/demo page showing Auth, persisted state and team RPCs. Integrate these patterns into the actual Axiom frontend; this is not a recreation of the full frontend.
- `.env.example`: variable names only.
- `docs/DEPLOY.md`: deployment and smoke tests.

## Required secrets/configuration

Worker secrets (set using `wrangler secret put`):
- `AI_API_KEY`: API key for your chosen OpenAI-compatible model provider.
- Optional `AI_BASE_URL`: provider base URL (default OpenAI API).
- Optional `AI_MODEL`: model identifier (default `gpt-4o-mini`).

Worker vars in `wrangler.toml`:
- `SUPABASE_URL`: project URL.
- `SUPABASE_ANON_KEY`: public/publishable key, not a service-role key.
- `ALLOWED_ORIGINS`: comma-separated exact frontend origins.

Never put service-role keys, model API keys, OAuth client secrets, or refresh tokens in frontend files or Git.

## Safety notes

- Existing Supabase team tables and RPCs were observed. The migration is additive and does not drop or rewrite them.
- Review RLS policies and test with two separate accounts before using real student data.
- The agent retrieves only current-user state and explicitly allowlisted official HOSA/DECA URLs. It does not claim to browse all organizational sites.
- Existing `levelup_teams` exposes `invite_code` in its table schema. Do not return whole team rows to the frontend; use narrowly scoped RPCs/views instead.
- No deployment has been performed by this repository change.

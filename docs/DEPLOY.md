# Axiom deployment guide

## Current limits you must know

This repo's starting branch was effectively empty (README only). This branch adds backend/Worker scaffolding and a small integration example, **not the complete Axiom lesson frontend**. It is not safe to claim a one-click production deployment until the real frontend is integrated and all steps below pass. Existing Supabase team tables/functions were inspected and preserved; this migration adds lesson results, personal calendar, and shared resources.

## 1. GitHub

1. Open the `build/deploy-ready-foundation` branch.
2. Review the diff. Do not merge until secrets, frontend integration, and the security tests are complete.
3. Download the branch ZIP only if you want the files locally; the branch is the source of truth.

## 2. Supabase migration

1. Open the existing project in Supabase.
2. Back up the current schema/data.
3. Open SQL Editor and review `supabase/migrations/20261021010000_axiom_backend_foundation.sql`.
4. Run the migration in a staging project first. It is additive and doesn't drop existing tables.
5. Confirm the three new tables exist and RLS is enabled.
6. In Authentication, keep Google OAuth redirect URLs configured for your actual frontend origin.
7. Do not expose service_role or secret keys in frontend files.

The existing project already has `user_app_state`, `levelup_teams`, `levelup_team_members`, and `levelup_team_events` plus team RPCs. Existing team rows include an `invite_code` column; do not query full team rows for ordinary member listings.

## 3. Cloudflare Worker

Requires Node.js and npm on your computer.

1. Install Node.js LTS from https://nodejs.org/.
2. Download the branch ZIP and extract it.
3. Open a terminal in the extracted repository's `worker` folder.
4. Run `npm install`.
5. Edit `wrangler.toml` and replace `SUPABASE_ANON_KEY` with the project's public/publishable key, and replace `ALLOWED_ORIGINS` with the exact deployed frontend origin (scheme + hostname, no trailing path).
6. Run `npx wrangler login` and complete the Cloudflare authorization.
7. Set the AI secret: `npx wrangler secret put AI_API_KEY`. Paste the provider key only into the interactive terminal prompt.
8. If using a non-default provider URL, run `npx wrangler secret put AI_BASE_URL` and enter its documented API base URL.
9. Run `npx wrangler dev`; test `GET /health` and unauthenticated `POST /api/agent` (must return 401).
10. Run `npx wrangler deploy` only after tests pass. This creates/updates the Worker named in `wrangler.toml`; do not overwrite the existing frontend Worker by renaming it.
11. Copy the new Worker URL and configure it in the existing frontend.

## 4. Frontend integration

Use the existing Axiom frontend repository/source. This branch's `web` directory contains only integration examples, not the full frontend. Configure:
- Supabase URL + public/publishable key
- Agent Worker URL
- Supabase session bearer token on agent requests
- persistence calls for lesson results, calendar, and user_app_state
- team UI using existing `create_levelup_team`, `join_levelup_team`, and `rotate_levelup_team_invite` RPCs.

Never send a service-role key to the browser. Do not expose team invite codes by selecting every column from `levelup_teams`.

## 5. Smoke tests before production

- Two test accounts cannot read each other's `user_app_state`, lesson results, or personal calendar.
- Each account can save and reload its own lesson result/calendar event.
- Team owner can create a team and rotate its invite; member can join with a valid code.
- Invalid/revoked codes fail; non-members cannot read team events/resources.
- Worker health endpoint works.
- Agent request without a valid Supabase token returns 401.
- Valid user can ask a question; response is based only on supplied personal context and approved source excerpts.
- Arbitrary domains, redirects, non-HTTPS URLs, and unapproved domains are rejected.
- Agent cannot yet use team context; it explicitly returns 501 for `teamId` requests until membership-scoped Worker integration is implemented.
- No secret appears in Git, built frontend assets, or browser network responses.

## Known follow-up required

- Integrate the real Axiom frontend; this repo branch does not include it.
- Add server-side membership-checked team context to the agent before enabling team-aware agent queries.
- Google Drive OAuth/refresh-token storage and folder-scoped file operations are not implemented in this foundation.
- Source extraction is basic HTML text stripping, not a full RAG ingestion/indexing system. Only use URLs from the explicit allowlist and verify citations.
- Add rate limiting/abuse controls (Cloudflare rate-limiting rules or equivalent) before public production use.
- Run TypeScript/build tests locally and review deployment logs; tool access here cannot prove the external build environment passes.

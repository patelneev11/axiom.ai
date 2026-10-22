# Axiom deployment guide

This repository branch contains a new Axiom web app shell, Supabase migration, and Cloudflare Worker. It is **not a proven production release yet**: Google Cloud OAuth/Picker values, the Agent Worker URL, the AI provider key, and the Supabase service-role secret must be configured by the project owner. The seeded question bank currently contains 10 questions per course and is reused across lessons; it is not the planned 1,500-question vetted curriculum or 10 × 50-question practice-test bank.

## 1. Export the code

1. Open the [build/deploy-ready-foundation branch](https://github.com/patelneev11/axiom.ai/tree/build/deploy-ready-foundation).
2. Download the branch ZIP from GitHub's **Code → Download ZIP**, or use the branch directly.
3. Keep this branch separate from `main` until the build and security checks pass.

## 2. Apply the Supabase migration

1. Back up the current database schema and any important data.
2. Open the Supabase project and go to **SQL Editor**.
3. Open `supabase/migrations/20261021010000_axiom_backend_foundation.sql` from this repository and review it.
4. Run it in a staging project first, then the intended project when ready.
5. Verify the new tables exist: `axiom_lesson_results`, `axiom_user_progress`, `axiom_personal_calendar`, and `axiom_team_resources`.
6. Confirm RLS is enabled and authenticated users can only select their own lesson results/progress/calendar. Lesson result writes are intentionally restricted to the Worker-only database function.
7. Keep Supabase Google OAuth provider settings configured with your real frontend callback/redirect URLs.

The migration is additive and does not drop existing Axiom/team tables. It adds a server-only `record_axiom_lesson_result` function; only the Supabase `service_role` may execute it.

## 3. Configure and deploy the Cloudflare Worker

Requires Node.js LTS and npm.

1. Open a terminal in the extracted repository's `worker` folder.
2. Run `npm install`.
3. Open `wrangler.toml`. Confirm `SUPABASE_URL` and `SUPABASE_ANON_KEY` match the intended Supabase project. Replace `ALLOWED_ORIGINS` with the exact deployed frontend origin(s), comma-separated, including `https://` and no path.
4. Run `npx wrangler login`.
5. Set the AI provider key: `npx wrangler secret put AI_API_KEY`.
6. Set the Supabase **service-role secret**: `npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY`. Paste it only in the interactive terminal prompt. Never put it in the frontend, Git, or `wrangler.toml`.
7. Optionally set `AI_BASE_URL` if using a compatible provider other than OpenAI's default endpoint.
8. Run `npm run check` to type-check the Worker.
9. Run `npx wrangler dev`. Confirm `GET /health` responds with `{"ok":true}`; unauthenticated calls to `/api/questions`, `/api/grade`, and `/api/agent` must return 401.
10. Run `npx wrangler deploy` only when checks pass. This deploys the separate Worker named in `wrangler.toml`; do not rename it to the name of your existing frontend Worker.
11. Copy the deployed Worker origin for the next step.

The Worker routes are:
- `GET /health`: basic health check
- `GET /api/questions?course=...&unit=1&lesson=1`: authenticated questions without answer keys
- `POST /api/grade`: authenticated grading; answer keys stay in Worker code and scores are saved through the server-only SQL function
- `POST /api/agent`: authenticated assistant with official HOSA/DECA host allowlisting and membership-checked team context

## 4. Configure the frontend

1. Open `web/src/config.js`.
2. Confirm the Supabase public/publishable key belongs to the intended project. This key is designed to be used in a browser; it is not a service-role key.
3. Set `window.AXIOM_AGENT_URL` to the Worker origin from step 3.
4. To enable Google Drive folder selection, create a Google Cloud OAuth **Web application** client and a referrer-restricted API key. Enable the Google Picker API and the Drive API in that Cloud project. Set:
   - `AXIOM_GOOGLE_CLIENT_ID`
   - `AXIOM_GOOGLE_API_KEY`
   - `AXIOM_GOOGLE_APP_ID` (the Google Cloud project number)
5. In Google Cloud, authorize the exact frontend origin and configure the OAuth consent screen. The Picker integration requests the `drive.file` scope and lets a user choose a folder. It stores the selected folder URL in the team record; it does not automatically ingest all Drive files or bypass Drive sharing permissions.
6. Serve the `web/` folder using Cloudflare Pages or another static host. The app entry is `web/index.html`; no frontend build step is required.
7. Add the deployed frontend origin to Worker `ALLOWED_ORIGINS` and redeploy the Worker if you change it.

## 5. Verify the app

Use two separate test accounts and a test team, not real student data.

- Sign up, confirm email, sign in, sign out, and test Google sign-in.
- Confirm lesson questions load from the Worker and answer keys are not included in the question response.
- Complete a lesson and verify the Worker calculates the score, saves it, and updates XP/hearts. Retaking the same lesson must not award XP twice.
- Confirm a user cannot insert/update lesson results or progression directly through the browser's Supabase client.
- Confirm each account cannot read the other account's lesson results, progression, or personal calendar.
- Create a team, join with an invite code, rotate the invite as owner, and confirm non-members cannot read events/resources or use team context in the agent.
- Choose a Drive folder and save its link. Test that a teammate who has not been granted access by Google cannot open private Drive content.
- Test agent calls with no token, an expired token, a nonmember team ID, an unapproved domain, a redirecting source URL, and an allowed official HOSA/DECA page.
- Review the latest GitHub Actions run at [Axiom checks](https://github.com/patelneev11/axiom.ai/actions).

## Current scope limits — do not mistake these for completed features

- The question bank is a starter set of 10 questions per course reused across the lesson path. The planned 50 lessons × 10 unique questions per course and 10 practice tests × 50 unique questions per course have not yet been authored/reviewed.
- Practice-test mode currently uses a 10-question sample set, not a complete 50-question, 60-minute test engine.
- The Drive integration is a Google Picker folder selector/link, not full Drive file search, ingestion, or sync.
- Source retrieval is limited to explicitly supplied HTTPS URLs on the official host allowlist and simple HTML text extraction. This is not a complete indexed RAG corpus of every official HOSA/DECA page.
- The lesson grade and progression RPC are server-side, but production deployment still needs integration tests against the actual configured Supabase project and Worker secrets.
- Add Cloudflare rate limiting and monitor Worker logs before exposing the agent publicly.

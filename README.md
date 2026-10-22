# Axiom

**A competitive study workspace for HOSA and DECA.**

Axiom brings course-based learning, practice, progress tracking, and team study workflows into one workspace. This repository is the source of truth for the application and its supporting backend.

## Product goals

- HOSA Biotechnology preparation
- HOSA Biomedical Debate preparation
- DECA FTDM preparation
- Lesson progression with Easy, Medium, Hard, and Expert levels
- Practice tests, accuracy and time-spent statistics
- Personal calendar for competition dates and study milestones
- Hearts, XP, and lesson completion tracking
- Team workspaces with individual progress kept private
- A study assistant constrained to the user's authorized data and approved official sources

## Technology

- **Frontend:** web application
- **Authentication and persistence:** Supabase Auth and PostgreSQL with Row Level Security (RLS)
- **Agent API:** Cloudflare Worker
- **Team workflows:** Supabase-backed team membership, events, and shared resources

## Repository layout

- `worker/` — Cloudflare Worker API and Wrangler configuration
- `supabase/migrations/` — reviewed, version-controlled database migrations
- `web/` — frontend and integration assets
- `docs/` — setup, integration, security, and deployment instructions
- `.env.example` — names of required public frontend configuration variables (never real secrets)

## Development status

This repository is being assembled in stages. Check the branch and pull request you're working from before deploying. **Do not assume that a scaffold or draft pull request represents a complete production release.** The existing production frontend must be present and integrated, database migrations must be tested, and all critical flows must pass the deployment checklist.

See [the deployment guide](docs/DEPLOY.md) for setup and verification instructions.

## Configuration and secrets

Frontend configuration should use the Supabase project URL and its public/publishable (or legacy anon) key. Server-side secrets belong only in the Cloudflare Worker secret store.

Never commit:
- Supabase `service_role` or secret keys
- AI provider API keys
- Google OAuth client secrets or refresh tokens
- User data, passwords, or local `.env` files

Use `.env.example` as a template. Configure exact allowed frontend origins for CORS; do not use a wildcard for authenticated endpoints.

## Security expectations

- All private user data must be protected by RLS and ownership checks.
- Team information must be visible only to authenticated team members, with role checks for administrative actions.
- Never trust a user ID, team role, score, XP amount, or invite-code status supplied by the browser without server/database validation.
- The agent must validate the Supabase session, constrain data access to the authenticated user or verified team membership, and only use explicitly approved HOSA/DECA source URLs.
- Treat retrieved webpages and user-provided text as untrusted content, not as instructions.
- Verify isolation with at least two separate test accounts before using real student data.

## Deployment checklist

- [ ] Confirm the full frontend and question bank are present in the repository.
- [ ] Install dependencies and pass the frontend and Worker builds.
- [ ] Review migrations and back up the existing database before applying changes.
- [ ] Test sign-up, email confirmation, Google OAuth, sign-in, sign-out, and session persistence.
- [ ] Test saving and reloading lesson results and calendar events.
- [ ] Test course, difficulty, and statistics calculations.
- [ ] Test team creation, joining, invite rotation, member permissions, and private progress.
- [ ] Test agent authentication, allowed-source restrictions, and refusal of unauthorized data requests.
- [ ] Configure Cloudflare secrets without committing them.
- [ ] Verify the deployed frontend and Worker endpoints using the smoke tests in `docs/DEPLOY.md`.

## Contributing

Keep changes focused and reviewable. Add schema changes as new migrations rather than destructive edits to live tables. Document new environment variables and add tests for security-sensitive behavior.

## License

No license has been added yet. All rights remain with the respective copyright holders unless a license is added to this repository.

# Integrating the existing Axiom frontend

This repository did not contain the full frontend when inspected; the default branch README was the only file found. Use this contract to connect the real Axiom UI without replacing its lesson content or styling.

## Client configuration

Initialize the existing Supabase client with the project's URL and public/publishable key. Never include a service-role key.

Required values:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- Agent API URL: the deployed `axiom-agent-api` Worker origin.

## Persist lesson results

After a lesson is actually graded, upsert one row into `axiom_lesson_results`:
- `user_id`: the authenticated user's ID from the verified Supabase session
- `course_slug`: one of `hosa-biotechnology`, `hosa-biomedical-debate`, `deca-ftdm`
- `unit_number`, `lesson_number`
- `difficulty`: `easy`, `medium`, `hard`, or `expert`
- `correct_answers`, `total_questions`, `duration_seconds`, `xp_earned`

Use conflict key `user_id,course_slug,unit_number,lesson_number`. Treat a failed write as a save failure and let the user retry; don't silently show an unsaved lesson as persisted.

## Persist personal calendar

Use `axiom_personal_calendar` for personal events. Select, insert, update, and delete through the signed-in Supabase client. RLS limits access to the owning user. Keep team events in `levelup_team_events`, not the personal table.

## Existing team RPCs

The existing project already has:
- `create_levelup_team(team_name)`
- `join_levelup_team(invite_code)`
- `rotate_levelup_team_invite(target_team_id)`

Call these via `supabase.rpc(...)` after sign-in. Never assign the `owner` role from client-supplied values. The project currently exposes an invite code column in `levelup_teams`; do not select `*` or display invite codes to every team member. Use the owner-only rotate function to revoke an old code by rotating it.

## Agent request

Pass the access token from the current Supabase session:
```ts
const { data: { session } } = await supabase.auth.getSession();
if (!session?.access_token) throw new Error("Sign in required");
const response = await fetch(AGENT_URL + "/api/agent", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${session.access_token}`,
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    message: userQuestion,
    course: currentCourse,
    sourceUrls: approvedSourceUrls
  })
});
if (!response.ok) throw new Error("Axiom agent request failed");
const result = await response.json();
```

Only send source URLs selected from the app's explicit approved-source catalog. The Worker independently validates the domain allowlist. The Worker context currently supports the user's `user_app_state`; team-aware agent context should not be exposed in UI until the Worker has a membership-checked team context implementation.

## Statistics

Calculate per-difficulty accuracy from saved lesson results:
`sum(correct_answers) / sum(total_questions) * 100`
for each difficulty. Do not average lesson percentages equally when lesson question counts differ. Total time is the sum of `duration_seconds`. Use the lesson path's canonical difficulty assignment and keep every unit at the configured 2 Easy / 4 Medium / 3 Hard / 1 Expert distribution.

## Hearts and XP

Do not accept arbitrary client-supplied XP/heart totals as trusted. For a production-grade economy, implement a server-side completion RPC that grades against trusted answer keys and applies XP/heart changes transactionally. The current foundation stores results, but does not yet implement a trusted answer-key grading service or atomic heart regeneration.

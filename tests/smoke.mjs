import { readFileSync, existsSync } from "node:fs";
import assert from "node:assert/strict";

const html = readFileSync("web/index.html", "utf8");
const config = readFileSync("web/src/config.js", "utf8");
const app = readFileSync("web/src/main.js", "utf8");
const worker = readFileSync("worker/src/index.ts", "utf8");
const migration = readFileSync("supabase/migrations/20261021010000_axiom_backend_foundation.sql", "utf8");

assert.ok(html.includes("./src/config.js"), "HTML must load runtime config before app");
assert.ok(html.indexOf("./src/config.js") < html.indexOf("./src/main.js"), "runtime config must load before app");
assert.ok(existsSync("web/src/main.js"), "frontend entry point must exist");
assert.ok(config.includes("sb_publishable_"), "browser config should use a Supabase publishable key");
assert.ok(!config.includes("SUPABASE_SERVICE_ROLE_KEY =") && !config.includes("SUPABASE_SERVICE_ROLE_KEY="), "browser config must not define a service-role secret");
assert.ok(app.includes("hosa-biotechnology") && app.includes("hosa-biomedical-debate") && app.includes("deca-ftdm"), "all three courses must exist");
assert.ok(app.includes("units:[") && app.includes("easy") && app.includes("medium") && app.includes("hard") && app.includes("expert"), "lesson difficulty levels must exist");
assert.ok(app.includes("axiom_lesson_results") || app.includes("axiom_lesson_results"), "lesson result persistence must be wired");
assert.ok(app.includes("axiom_personal_calendar"), "personal calendar persistence must be wired");
assert.ok(app.includes("create_levelup_team") && app.includes("join_levelup_team"), "team creation and joining RPCs must be wired");
assert.ok(app.includes("/api/agent"), "agent endpoint must be wired");
assert.ok(worker.includes("/auth/v1/user"), "Worker must validate Supabase user sessions");
assert.ok(worker.includes("OFFICIAL_HOSTS"), "Worker must enforce official source host allowlist");
assert.ok(worker.includes("AUTHORIZED_TEAM_CONTEXT_JSON"), "Worker must pass only verified team context");
assert.ok(migration.includes("enable row level security") && migration.includes("auth.uid()"), "new user tables must use RLS and ownership policies");

console.log("Axiom static smoke checks passed.");

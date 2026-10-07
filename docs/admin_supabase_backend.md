# Admin dashboard backend contract

`AdminDashboardScreen` is the sole Admin UI. It preserves the existing profile
and AuthService sign-out flow. Admin data access uses AdminSupabaseService and
the existing Supabase initialization/configuration pattern. No Admin Firestore
queries or writes remain. Shared authentication and Firebase integrations remain.

## Connected reads

- `restaurants`: `id`, `name`, `cuisine`, `location`, `is_active`,
  `is_queue_available`, `est_wait` (established by SupabaseService).
- `profiles`: `id`, `full_name`, `email`, `role` (established by AuthService).

Reads are snapshots on opening the screen, not subscriptions. Empty responses
stay empty. Unconfigured Supabase or failed reads use clearly identified example
data. Price and phone are displayed as unavailable on loaded restaurants because
no corresponding Supabase columns are established. Read failures are not treated
as evidence that a table is absent. The deployed schema was not accessed.

All mutation controls operate on session-local copies, including when reads
succeed. Results are marked local preview. No account is created, suspended,
promoted, or deleted; no alert is delivered; no reservation/queue is frozen or
flushed. Reopening discards edits. Suspension flags on profile snapshots are
local placeholders because no persisted flag is established.

## Required backend work before enabling writes

These are proposed contracts, not claims that these tables/RPCs exist. No SQL
migration is applied: the repository contains no SQL schema, constraints, foreign
keys, or Admin authorization policies to migrate safely.

1. **Identity and authorization:** resolve how Firebase identity/current role
   maps to a Supabase authenticated identity/JWT. Current shared AuthService uses
   Firebase sign-in with a local fallback; the Admin UI role is not authorization.
   Add server-verified Admin permissions, RLS, and audit records for each action.
   Never trust a role selected in the client, or ship service-role credentials.
2. **Restaurants:** verify ID generation, required columns, defaults, ownership,
   FK/delete behavior, and Admin write policies on `restaurants`. Define whether
   Toggle Status means `is_active` or `is_queue_available` (these differ). Map
   address to the existing `location`; decide whether to add nullable `phone` and
   `price_level` columns or remove those inputs for persisted operations. Use an
   authorized mutation endpoint/RPC with validation and preferably soft deletion;
   do not assume deleting a restaurant may cascade safely.
3. **Users:** `profiles` exists in code, so a new users table is unnecessary.
   Define a persisted suspension flag (proposed `is_suspended boolean not null
   default false`) and enforcement at authenticated access boundaries. Add secure
   role/suspension endpoints with self-lockout/last-Admin checks and audit events.
   Account provisioning/deletion needs a secure server/Edge Function using the
   project's real auth provider; deleting a `profiles` row is not auth deletion.
4. **Broadcasts:** no table/delivery contract exists in repository code. Proposed
   `admin_broadcasts`: generated `id`, nonempty `title` and `message`, checked
   `priority` (`NORMAL`, `WARNING`, `URGENT`), `created_by`, `created_at`, and
   active/archived status. Add Admin-only insert policies and recipient read
   policies, plus delivery infrastructure if notifications are required.
5. **Freeze:** no settings table or RPC is established. Proposed singleton
   `platform_controls`: `platform_frozen`, `updated_by`, `updated_at`; authorized
   `set_platform_freeze` RPC. Queue/reservation creation must check the flag on
   the server within the transaction, not merely render a switch.
6. **Flush:** reuse `queue_entries`, whose code already uses `waiting`, `called`,
   and `cancelled` statuses. Add an authorized, audited `flush_waitlists` RPC
   that transactionally changes only eligible waiting/called entries to cancelled,
   records reason/time/actor, and returns an affected count. Scope and retention
   rules must be agreed; never delete all queue rows from Flutter.

AuthGate and existing profile-view routes already target the canonical screen.
The Home Admin button retrieves the current application profile; without an
Admin profile it routes to sign-in instead of fabricating one. The existing
Customer profile role-preview pattern remains unchanged; it is not a security
boundary and cannot authorize future privileged backend writes.

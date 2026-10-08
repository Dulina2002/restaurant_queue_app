# Admin Supabase backend contract

## VERIFIED CURRENT STATE

### Applied SCRUM-24 Admin security update (2026-10-08)

The project owner confirmed these changes are already live, applied manually in
the Supabase SQL Editor. The exact policy/helper definitions and a guarded,
re-runnable SQL record are in
[admin_supabase_security_applied.sql](admin_supabase_security_applied.sql).
No SQL was executed as part of this documentation task.

- **Profile creation:** `"Users can insert own profile."` now checks
  `auth.uid() = id AND role = 'customer'`, scoped `TO public`. The signup UI may
  still display privileged role options, but the database rejects non-customer
  self-profile creation under the recorded policy set.
- **Private authorization:** `admin_private.is_admin()` accepts no arguments,
  checks only `auth.uid()` against `public.profiles.role = 'admin'`, uses
  `SECURITY DEFINER` with an empty `search_path`, and is owned by `postgres`.
  PUBLIC/anon execution is revoked; authenticated receives schema USAGE and
  function EXECUTE. Keep this schema outside exposed API schemas and verify the
  owner's profiles RLS bypass, including FORCE RLS considerations.
- **Profile reads:** the separate permissive `"Admin read all profiles"` SELECT
  policy calls the helper for authenticated users. The existing own-profile
  SELECT policy remains intact. Admins can read all profiles; normal users retain
  self-only reads, assuming no other policy grants broader access.
- **Restaurant authorization:** `"Public manage restaurants"` was removed.
  `"Admin manage restaurants"` is permissive FOR ALL TO authenticated, with the
  helper in both USING and WITH CHECK. Existing public restaurant SELECT remains
  unchanged. Admin dashboard restaurant CRUD now persists to Supabase and is
  protected by this policy; price and phone remain session-only.

These changes do not authorize client self-promotion or privileged account
management. Audit other policies/grants and trusted role-provisioning paths to
ensure they cannot bypass these checks. No Broadcast, System, or queue changes
are included in this update.

The sections below preserve the earlier baseline and future requirements. Where
they describe self-only Admin reads, unrestricted restaurant mutations,
session-only restaurant CRUD, no database functions, or pending Auth integration, the applied update
above supersedes that historical state. The broad
`admin_supabase_migration_draft.sql` remains a future draft, not the record of
these applied changes; do not replay it to reproduce this update.

### Historical baseline and remaining proposals

The deployed database facts below were verified by the project owner in the
Supabase Table Editor and supplied for this documentation update. No database
migration or policy change is applied by this document.

### Deployed public schema

Existing tables: `menu_items`, `profiles`, `queue_entries`, `reservations`,
`restaurants`, and `tables`.

There is currently no broadcasts table, no `platform_settings` or
`system_settings` table, and no database RPC/function. The requirements below
are proposals, not implemented features.

### Restaurants

`public.restaurants` has these columns:

`id`, `name`, `cuisine`, `tag`, `location`, `rating`, `reviews_count`,
`is_active`, `is_queue_available`, `est_wait`, `waitlist_count`, `created_at`.

Current RLS policies:

- **Public read restaurants:** SELECT.
- **Public manage restaurants:** ALL, using `USING (true)`.

The public manage policy is unsafe for production Admin writes: it does not
restrict access to server-verified Admins. Merely adding another restrictive-looking
permissive Admin policy does not remove access granted by this broad policy.
The existing public mutation grant must be replaced/restricted as part of a
reviewed authorization migration before enabling production Admin mutations.

The UI address can map to `location`. Price and phone are not columns in this
verified schema and must remain explicitly local/display-only unless a separate
schema change is approved. ID type/generation, defaults, nullability, constraints,
and foreign-key/cascade behavior are not established by this column list.
`is_active` and `is_queue_available` are distinct controls; persistence must define
which one each UI action changes.

### Queue

`public.queue_entries` supports `waiting`, `called`, `seated`, and `cancelled`.
The queue model and existing app logic explicitly support `cancelled`.

Current RLS policies:

- **Public read queue_entries:** SELECT.
- **Public manage queue_entries:** ALL, using `USING (true)`.

This public manage policy is also unsafe. Production queue authorization must
replace/restrict that broad grant while preserving legitimate, narrowly scoped
Customer and staff workflows. An Admin-only RPC alone cannot secure the table
while unrestricted direct mutations remain allowed.

Global Waitlist Flush must never delete queue rows. Eligible `waiting`/`called`
entries should transition to `cancelled`; `seated` and already `cancelled`
entries and historical records must be preserved.

### Profiles and current Admin application behavior

`public.profiles` has `id`, `full_name`, and `role`; there is no `email` column.
RLS is enabled, and the confirmed current SELECT policy is `auth.uid() = id`.
It permits self-profile access, not an Admin-wide user directory.

`AdminDashboardScreen` is the canonical four-tab Admin UI. Its service reads
restaurant snapshots and selects only `id,full_name,role` from profiles. Profile
email displays as unavailable. Empty responses stay empty; failed/unconfigured
reads show labeled examples. All Admin mutations currently remain session-only
previews: no account changes, delivered broadcasts, persisted freeze, or queue
flush are performed. Reopening discards local edits.

The Firebase/Supabase authentication mismatch is assigned to another team member.
Database read success or a client-side Admin screen/profile is not proof of
privileged authorization. Firebase/Auth configuration and shared files are outside
this Admin task's scope.

## PROPOSED BACKEND REQUIREMENTS

The following tables, RPCs, policies, and supporting behavior must be designed,
reviewed, and deployed separately. None is claimed to exist today. No Flutter
client may contain service-role credentials or query `auth.users` directly.

### 1. Admin-only restaurant mutations

After Supabase Auth integration, authorize restaurant INSERT, UPDATE, and DELETE
using the authenticated identity and a server-controlled Admin role. Replace/restrict
**Public manage restaurants**; use appropriate `USING` checks for existing rows
and `WITH CHECK` checks for inserted/updated rows. Clients must not be able to
self-assign the role used for authorization.

Verify ID generation, required fields/defaults, allowed values, and dependent-row
behavior before implementing Add/Edit/Delete. Persist only verified columns.
Define Toggle Status semantics explicitly. Prefer deactivation through the existing
`is_active` field where deletion would destroy dependent history; hard deletion
requires an approved dependency/retention contract. Return authoritative results
and failures, and audit privileged mutations.

### 2. Broadcast persistence

Proposed new table: `public.broadcasts`.

| Column | Proposed contract |
| --- | --- |
| `id` | UUID primary key, generated by the database |
| `title` | Required text, nonempty after trimming |
| `message` | Required text, nonempty after trimming |
| `priority` | Required text, checked to NORMAL, WARNING, or URGENT |
| `status` | Required text, checked to active or archived; default active |
| `created_by` | Required authenticated Supabase user UUID; set/validated by trusted backend |
| `created_at` | Required timestamptz; default current database time |

Enable RLS with Admin-only creation/management and a separately reviewed recipient
read policy. Preserve creator/time attribution and define archival/audit behavior.
Read/create persistence does not itself deliver push notifications; delivery needs
its own backend workflow. Until deployed, retain explicit session-only broadcasts.

### 3. Platform freeze persistence

Proposed new singleton table: `public.platform_settings`.

| Column | Proposed contract |
| --- | --- |
| `id` | Integer primary key constrained to 1 |
| `platform_frozen` | Required boolean; default false |
| `updated_by` | Authenticated Supabase user UUID for the last change; nullable only before the first change |
| `updated_at` | Required timestamptz; default current database time |

Proposed RPC: `set_platform_freeze(p_frozen boolean)`, returning the saved flag
and update time. Require a server-verified Admin, set actor/time server-side, and
audit changes. RLS/grants must prevent non-Admin writes; decide separately who
may read the flag. Server-side queue/reservation creation must enforce the freeze
within transactions, with concurrency coordination so writes cannot bypass it.
Persisting a switch alone does not freeze the platform. Keep local behavior until
both persistence and enforcement are deployed.

### 4. Secure Global Waitlist Flush

Proposed RPC: `public.flush_waitlists()`, returning `affected_count bigint`.

Required contract:

- Require an authenticated Supabase identity and a server-verified Admin role;
  reject unauthenticated/non-Admin callers and do not trust a supplied actor/role.
- In one transaction, update only eligible entries whose status is `waiting` or
  `called` to `cancelled`. Do not delete any queue rows or modify seated/history rows.
- Coordinate concurrent queue transitions and define the flush cutoff/scope so
  arrivals and seating cannot race into unintended cancellation.
- Return the number of affected rows. Repeat calls should leave already cancelled
  rows untouched. Record the actor, timestamp, reason, and affected entry IDs in a
  proposed backend audit store; deploy any needed audit schema explicitly.
- Restrict execution grants to the intended authenticated role with the Admin
  check enforced inside the function. If SECURITY DEFINER is required, fix the
  search path, qualify objects, restrict ownership/privileges, and revoke default
  PUBLIC/anonymous execution.
- Replace/restrict **Public manage queue_entries** so direct client writes cannot
  bypass authorization. Retain separately scoped legitimate queue operations.

Flutter should retain the warning/confirmation dialog and call only this authorized
RPC once available. Until then, keep the non-destructive local simulation and
label it accordingly.

### 5. Admin-wide profile access and user management

Keep the existing self-profile SELECT policy. Admin-wide access requires a
separate reviewed Admin-only SELECT policy or secure backend directory endpoint,
checking a trusted role that users cannot modify themselves. Do not add anonymous
or unrestricted profile reads. Prevent policy recursion when checking roles and
return only the necessary `id`, `full_name`, and `role` fields.

Self-profile access and Admin-wide access are separate requirements; Supabase Auth
integration alone will not turn `auth.uid() = id` into a directory permission.

Privileged account provisioning/deletion, role assignment, and suspension require
separate authorized backend endpoints/RPCs, audit records, and last-Admin/self-lockout
rules. No suspension field/enforcement contract is verified. Deleting a profile
row is not deleting an authentication account. Leave these actions local-only
until their backend contracts are approved and deployed.

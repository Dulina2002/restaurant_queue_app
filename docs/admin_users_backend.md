# SCRUM-29 Admin Users backend (not deployed)

`admin-users/index.ts` verifies every POST bearer token with Supabase Auth, then
reads the verified caller UUID's `profiles.role` using a server-only privileged
client. Only `admin` is accepted. Client roles/metadata are never authorization.
OPTIONS is an unauthenticated CORS preflight; CORS itself grants no access.
Gateway JWT verification is enabled in configuration (`verify_jwt = true`). The
handler also verifies the bearer token with `getUser(token)` and checks the stored
Admin role internally as defense in depth. No privileged key is stored in Flutter;
Flutter supplies only its current session JWT.
The handler reads the verified caller's Auth Admin record to reject active bans
even if the ordinary Auth user response omits `banned_until`.
The privileged client uses the server-side Supabase secret key environment:
parse `SUPABASE_SECRET_KEYS` as a JSON dictionary and select its nonempty `default`
string. Fall back to `SUPABASE_SERVICE_ROLE_KEY` only when the dictionary variable
is absent. Present but malformed/missing-default dictionaries fail closed. Neither
key is returned to clients or logged. `SUPABASE_URL` remains environment-provided.

Actions: list paginates Auth Admin listUsers and joins profiles; invite sends an
email invitation and upserts id/full_name/role; change_role updates profiles;
suspend uses Auth ban_duration 876000h; activate uses none; delete uses Auth Admin
deleteUser and relies on the verified profiles FK ON DELETE CASCADE.
Profiles has no email or suspended column. Email and banned_until come from Auth.
Missing profiles return a missing-role label, never a metadata-derived Admin role.
SDK User typing does not declare banned_until, so the response field is accessed
through an explicit extension type. Verify this field against deployed Auth before
rollout. Names fall back to User. Role metadata is not synchronized/authoritative.

The UI awaits success before modifying rows and keeps dialogs open on errors.
Example records without IDs cannot be mutated. Restaurant behavior is unchanged;
Broadcast/System remain local previews. Existing own-profile and Admin RLS policies
are untouched. Normal unit/widget tests use a fake service, never live Auth APIs.

## Last-Admin safety and deployment blockers

The function counts Admin profiles and checks remaining unbanned Auth accounts.
Last usable Admin removal/demotion/suspension returns 409. To avoid concurrent
check-then-mutate races, ALL removal/demotion/suspension of current Admin profiles
also returns 409 until a durable serialized backend lifecycle workflow is designed.
Non-Admin lifecycle operations and Admin activation/promotion are implemented.
Do not remove this fail-closed guard on the basis of count checks alone. In-memory
Edge locks do not serialize multiple isolates. Direct role writes must also remain
restricted to trusted workflows. Verify no existing RLS/RPC self-promotion path.

Invitations and profile writes are not atomic: an email/Auth identity can exist
when the profile upsert fails. On SDK or transport failure, the function attempts
server-side Auth deletion of the invited UUID. Successful cleanup returns a safe
500 indicating the account was rolled back; already-sent invitation email cannot
be recalled. Failed or throwing cleanup returns a safe 500 indicating manual
Admin cleanup may be required before retrying. Compensation is not an atomic
transaction, and an ambiguous upsert failure may have committed a profile; the
verified cascading FK is required for cleanup. Deletion can fail for other
FKs or owned storage records. Verify dependencies and invitation Site URL/redirect
and mail configuration before deployment. Verify the Auth Admin ban field;
existing JWTs and application fallback auth can outlive bans, so review shared
session revocation/enforcement separately without changing Auth files here.

No function was deployed and no live database/RLS/Auth operation was executed.
Deno mocked endpoint tests cover missing/invalid JWTs, stored-role authorization
versus spoofed metadata, invite validation and CORS, missing secrets, dictionary
selection and invalid dictionaries, and profile/cleanup SDK and transport failures.
Ten new Flutter Users tests cover backend rendering, delayed success and failure
for invite/role/suspend/delete, and delayed activation. Existing five Admin tests
are preserved. These tests do not contact a live Supabase API.
Before rollout: extend mocked endpoint tests for pagination, missing users,
guarded Admin lifecycle operations;
then explicitly authorize staging integration tests. Confirm runtime secrets, API
response banned_until, profile UUID/FK and client error behavior. Add durable audit
logging/rate limits according to the deployment requirements. Listing currently
uses per-user profile lookups; review pagination/performance for large directories.

References: https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid
and https://supabase.com/docs/guides/auth/users (server-only Admin API).

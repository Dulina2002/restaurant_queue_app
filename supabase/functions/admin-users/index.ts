import { createClient, type User } from "npm:@supabase/supabase-js@2.100.0";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const roles = ["customer", "receptionist", "manager", "admin"];
class RequestError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}
const reply = (
  status: number,
  data: unknown = null,
  error: string | null = null,
) =>
  new Response(JSON.stringify({ success: error === null, data, error }), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
const text = (value: unknown) => typeof value === "string" ? value.trim() : "";
function privilegedKey(
  environment: (name: string) => string | undefined,
): string {
  const dictionary = environment("SUPABASE_SECRET_KEYS");
  if (dictionary !== undefined) {
    // A present but invalid dictionary is a configuration failure, not a reason
    // to silently downgrade to a legacy key. Never include its value in errors.
    try {
      const keys: unknown = JSON.parse(dictionary);
      if (keys && typeof keys === "object" && !Array.isArray(keys)) {
        const key = (keys as Record<string, unknown>).default;
        if (typeof key === "string" && key.trim()) return key.trim();
      }
    } catch {
      // Safe, fixed configuration error below; no raw parser error or secret.
    }
    throw new RequestError(500, "Admin service is not configured.");
  }
  const legacy = environment("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!legacy) throw new RequestError(500, "Admin service is not configured.");
  return legacy;
}
const suspended = (user: User) => {
  const until = (user as User & { banned_until?: string }).banned_until;
  return !!until && Date.parse(until) > Date.now();
};

export async function handleRequest(
  req: Request,
  clientFactory = createClient,
  environment = (name: string) => Deno.env.get(name),
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }
  if (req.method !== "POST") return reply(405, null, "Use POST.");
  try {
    const token = req.headers.get("Authorization")?.match(/^Bearer\s+(\S+)$/i)
      ?.[1];
    if (!token) throw new RequestError(401, "Authentication required.");
    const url = environment("SUPABASE_URL");
    const key = privilegedKey(environment);
    if (!url || !key) {
      throw new RequestError(500, "Admin service is not configured.");
    }
    // Never forward caller Authorization to this privileged client.
    const db = clientFactory(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const verified = await db.auth.getUser(token);
    if (
      verified.error || !verified.data.user || suspended(verified.data.user)
    ) {
      throw new RequestError(401, "Authentication required.");
    }
    // The ordinary /user response may omit ban information. Read the verified
    // caller through the Admin API before permitting privileged operations.
    const callerAuth = await db.auth.admin.getUserById(verified.data.user.id);
    if (callerAuth.error) {
      throw new RequestError(500, "Unable to verify account access.");
    }
    if (!callerAuth.data.user || suspended(callerAuth.data.user)) {
      throw new RequestError(401, "Authentication required.");
    }
    const caller = await db.from("profiles").select("role").eq(
      "id",
      verified.data.user.id,
    ).maybeSingle();
    if (caller.error) {
      throw new RequestError(500, "Unable to verify Admin authorization.");
    }
    if (caller.data?.role !== "admin") {
      throw new RequestError(403, "Admin access required.");
    }
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      throw new RequestError(400, "Invalid JSON.");
    }
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      throw new RequestError(400, "Invalid request.");
    }
    const action = text(body.action);
    const profileFor = async (id: string) => {
      const result = await db.from("profiles").select("id,full_name,role").eq(
        "id",
        id,
      ).maybeSingle();
      if (result.error) {
        throw new RequestError(500, "Unable to read user profile.");
      }
      return result.data;
    };
    const representation = async (user: User) => {
      const profile = await profileFor(user.id);
      return {
        id: user.id,
        email: user.email ?? "",
        full_name: profile?.full_name || "User",
        role: profile?.role ?? null,
        suspended: suspended(user),
      };
    };
    const allAuthUsers = async () => {
      const users: User[] = [];
      for (let page = 1;; page++) {
        const result = await db.auth.admin.listUsers({ page, perPage: 100 });
        if (result.error) {
          throw new RequestError(500, "Unable to list Auth users.");
        }
        users.push(...result.data.users);
        if (result.data.users.length < 100) return users;
      }
    };
    if (action === "list") {
      const authUsers = await allAuthUsers();
      const result = [];
      for (const user of authUsers) result.push(await representation(user));
      return reply(200, result);
    }
    if (action === "invite") {
      const email = text(body.email),
        name = text(body.full_name),
        role = text(body.role);
      if (
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254 ||
        !name || name.length > 200 || !roles.includes(role)
      ) {
        throw new RequestError(
          400,
          "Valid email, full name and role are required.",
        );
      }
      const invited = await db.auth.admin.inviteUserByEmail(email);
      if (invited.error || !invited.data.user) {
        throw new RequestError(
          400,
          "Invitation failed. Check the email and existing account.",
        );
      }
      let profileSaved = false;
      try {
        const profile = await db.from("profiles").upsert({
          id: invited.data.user.id,
          full_name: name,
          role,
        });
        profileSaved = !profile.error;
      } catch {
        // Transport exceptions require compensation too, not just SDK errors.
      }
      if (!profileSaved) {
        let cleanedUp = false;
        try {
          const cleanup = await db.auth.admin.deleteUser(invited.data.user.id);
          cleanedUp = !cleanup.error;
        } catch {
          // Do not leak cleanup internals or replace the original safe error.
        }
        throw new RequestError(
          500,
          cleanedUp
            ? "Invitation/profile creation failed and the invited account was rolled back. The invitation email may already have been sent. Check configuration before retrying."
            : "Invitation/profile creation failed and cleanup could not be completed. Manual Admin cleanup may be required before retrying.",
        );
      }
      return reply(200, await representation(invited.data.user));
    }
    if (!["change_role", "suspend", "activate", "delete"].includes(action)) {
      throw new RequestError(400, "Unsupported action.");
    }
    const id = text(body.user_id);
    if (
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        id,
      )
    ) throw new RequestError(400, "Valid user ID required.");
    const target = await db.auth.admin.getUserById(id);
    if (target.error || !target.data.user) {
      throw new RequestError(
        target.error?.status === 404 ? 404 : 500,
        "Unable to find target user.",
      );
    }
    const profile = await profileFor(id);
    const role = text(body.role);
    if (action === "change_role" && !roles.includes(role)) {
      throw new RequestError(400, "Invalid role.");
    }
    const removesAdmin = profile?.role === "admin" &&
      (action === "delete" || action === "suspend" ||
        (action === "change_role" && role !== "admin"));
    if (removesAdmin) {
      const admins = await db.from("profiles").select("id").eq("role", "admin");
      if (admins.error) {
        throw new RequestError(500, "Unable to verify remaining Admins.");
      }
      const authUsers = await allAuthUsers();
      const active = admins.data.filter((p) =>
        authUsers.some((u) => u.id === p.id && !suspended(u))
      );
      if (
        admins.data.length <= 1 ||
        active.filter((p) => p.id !== id).length === 0
      ) {
        throw new RequestError(
          409,
          "Cannot remove or suspend the last usable Admin.",
        );
      }
      // A check then Auth mutation cannot be made atomic by an Edge isolate.
      // Fail closed until a durable serialized Admin lifecycle workflow exists.
      throw new RequestError(
        409,
        "Admin removal, demotion and suspension require a serialized backend workflow. Non-Admin operations remain available.",
      );
    }
    if (action === "change_role") {
      if (!profile) throw new RequestError(404, "Target profile is missing.");
      const updated = await db.from("profiles").update({ role }).eq("id", id)
        .select("id").single();
      if (updated.error) throw new RequestError(500, "Role update failed.");
      return reply(200, await representation(target.data.user));
    }
    if (action === "delete") {
      const deleted = await db.auth.admin.deleteUser(id);
      if (deleted.error) {
        throw new RequestError(
          500,
          "User deletion failed. Check dependent records.",
        );
      }
      return reply(200, { id, deleted: true });
    }
    const updated = await db.auth.admin.updateUserById(id, {
      ban_duration: action === "suspend" ? "876000h" : "none",
    });
    if (updated.error || !updated.data.user) {
      throw new RequestError(500, "User access update failed.");
    }
    return reply(200, await representation(updated.data.user));
  } catch (error) {
    if (error instanceof RequestError) {
      return reply(error.status, null, error.message);
    }
    // No raw SDK error, token, request body or personal data in responses/logs.
    console.error("admin-users unexpected failure");
    return reply(500, null, "Unexpected Admin service failure.");
  }
}

if (import.meta.main) Deno.serve((req) => handleRequest(req));

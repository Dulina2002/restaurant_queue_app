import { createClient } from "npm:@supabase/supabase-js@2.100.0";
import { handleRequest } from "./index.ts";

function assert(value: boolean, message: string) {
  if (!value) throw new Error(message);
}
const req = (body: unknown, token = true) =>
  new Request("http://local.test", {
    method: "POST",
    headers: token ? { Authorization: "Bearer test-token" } : {},
    body: JSON.stringify(body),
  });
const legacyEnvironment = (name: string) =>
  name === "SUPABASE_SECRET_KEYS" ? undefined : "test";
function fake(role: string | null, valid = true, banned = false) {
  let reads = 0;
  const client = {
    auth: {
      admin: {
        getUserById: (id: string) => {
          assert(id === "verified-id", "Ban lookup must use verified caller");
          return Promise.resolve({
            error: null,
            data: {
              user: {
                id,
                banned_until: banned ? "2999-01-01T00:00:00Z" : null,
              },
            },
          });
        },
      },
      getUser: (token: string) => {
        assert(token === "test-token", "Verify exact supplied token");
        return Promise.resolve({
          error: valid ? null : {},
          data: {
            user: valid
              ? { id: "verified-id", user_metadata: { role: "admin" } }
              : null,
          },
        });
      },
    },
    from: (table: string) => {
      reads++;
      assert(table === "profiles", "Only profile authorization read");
      return {
        select: () => ({
          eq: (column: string, id: string) => {
            assert(
              column === "id" && id === "verified-id",
              "Caller identity must come from Auth",
            );
            return {
              maybeSingle: () =>
                Promise.resolve({
                  error: null,
                  data: role ? { role } : null,
                }),
            };
          },
        }),
      };
    },
  };
  return {
    factory: (() => client) as unknown as typeof createClient,
    reads: () => reads,
  };
}
Deno.test("Missing bearer token is rejected before privileged client construction", async () => {
  let created = false;
  const factory = (() => {
    created = true;
    throw new Error("Must not construct");
  }) as typeof createClient;
  const response = await handleRequest(
    req({ action: "list" }, false),
    factory,
    legacyEnvironment,
  );
  assert(response.status === 401 && !created, "401 without privileged access");
});
Deno.test("Invalid JWT is rejected before profile access", async () => {
  const f = fake("admin", false);
  const response = await handleRequest(
    req({ action: "list" }),
    f.factory,
    legacyEnvironment,
  );
  assert(
    response.status === 401 && f.reads() === 0,
    "Invalid JWT cannot query profiles",
  );
});
for (const role of ["customer", null]) {
  Deno.test(`Metadata/client Admin claim cannot authorize profile role ${role}`, async () => {
    const f = fake(role);
    const response = await handleRequest(
      req({ action: "list", role: "admin", user_id: "spoofed" }),
      f.factory,
      legacyEnvironment,
    );
    assert(response.status === 403, "Must use stored profile role");
  });
}
Deno.test("Verified Admin still receives validation errors", async () => {
  const f = fake("admin");
  const response = await handleRequest(
    req({ action: "invite", email: "bad", full_name: "", role: "root" }),
    f.factory,
    legacyEnvironment,
  );
  assert(response.status === 400, "Reject malformed invite");
  const body = await response.json();
  assert(
    body.success === false && typeof body.error === "string",
    "Consistent error envelope",
  );
});
Deno.test("CORS preflight does not access Auth or Admin APIs", async () => {
  const f = fake("customer");
  const response = await handleRequest(
    new Request("http://local.test", { method: "OPTIONS" }),
    f.factory,
    legacyEnvironment,
  );
  assert(response.status === 204 && f.reads() === 0, "Preflight only");
  assert(
    response.headers.get("Access-Control-Allow-Methods") === "POST, OPTIONS",
    "CORS methods",
  );
});

Deno.test("Missing server secret fails without constructing a client", async () => {
  let created = false;
  const factory = (() => {
    created = true;
    throw new Error("Unexpected client");
  }) as typeof createClient;
  const response = await handleRequest(
    req({ action: "list" }),
    factory,
    (name) => name === "SUPABASE_URL" ? "http://local.test" : undefined,
  );
  assert(
    response.status === 500 && !created,
    "Missing secrets must fail closed",
  );
});
Deno.test("Default injected secret is preferred over legacy key", async () => {
  const f = fake("admin");
  let received = "";
  const factory = ((url: string, key: string) => {
    received = key;
    return f.factory(url, key);
  }) as typeof createClient;
  const response = await handleRequest(
    req({ action: "invalid" }),
    factory,
    (name) =>
      name === "SUPABASE_SECRET_KEYS"
        ? JSON.stringify({ default: "server-secret", other: "not-selected" })
        : "legacy-sentinel",
  );
  assert(
    received === "server-secret" && response.status === 400,
    "Use dictionary default only",
  );
  const output = await response.text();
  assert(
    !output.includes("server-secret") && !output.includes("legacy-sentinel"),
    "Never disclose keys",
  );
});
for (
  const dictionary of [
    "not-json",
    "{}",
    "[]",
    '{"default":42}',
    '{"default":""}',
  ]
) {
  Deno.test(`Invalid secret dictionary fails closed: ${dictionary}`, async () => {
    let created = false;
    const factory = (() => {
      created = true;
      throw new Error("Unexpected client");
    }) as typeof createClient;
    const response = await handleRequest(
      req({ action: "list" }),
      factory,
      (name) =>
        name === "SUPABASE_SECRET_KEYS" ? dictionary : "legacy-sentinel",
    );
    assert(
      response.status === 500 && !created,
      "Do not fallback for invalid injected dictionary",
    );
    assert(
      !(await response.text()).includes("legacy-sentinel"),
      "Safe error only",
    );
  });
}
for (const profileThrows of [false, true]) {
  for (const cleanup of ["success", "error", "throw"]) {
    Deno.test(`Invite profile failure compensates: profileThrows=${profileThrows}, cleanup=${cleanup}`, async () => {
      const deleted: string[] = [];
      const client = {
        auth: {
          getUser: () =>
            Promise.resolve({ error: null, data: { user: { id: "caller" } } }),
          admin: {
            getUserById: () =>
              Promise.resolve({
                error: null,
                data: { user: { id: "caller" } },
              }),
            inviteUserByEmail: () =>
              Promise.resolve({
                error: null,
                data: { user: { id: "invited-id", email: "new@example.com" } },
              }),
            deleteUser: (id: string) => {
              deleted.push(id);
              if (cleanup === "throw") {
                return Promise.reject(new Error("raw-sensitive-error"));
              }
              return Promise.resolve({
                error: cleanup === "error"
                  ? { message: "raw-sensitive-error" }
                  : null,
              });
            },
          },
        },
        from: () => ({
          select: () => ({
            eq: () => ({
              maybeSingle: () =>
                Promise.resolve({ error: null, data: { role: "admin" } }),
            }),
          }),
          upsert: () =>
            profileThrows
              ? Promise.reject(new Error("raw-sensitive-error"))
              : Promise.resolve({ error: { message: "raw-sensitive-error" } }),
        }),
      };
      const factory = (() => client) as unknown as typeof createClient;
      const response = await handleRequest(
        req({
          action: "invite",
          email: "new@example.com",
          full_name: "New User",
          role: "customer",
        }),
        factory,
        legacyEnvironment,
      );
      const output = await response.json();
      assert(
        response.status === 500 && output.success === false,
        "Profile failure must not report success",
      );
      assert(
        deleted.length === 1 && deleted[0] === "invited-id",
        "Compensate only invited UUID",
      );
      assert(
        output.error.includes(
          cleanup === "success" ? "rolled back" : "Manual Admin cleanup",
        ),
        "Report safe cleanup outcome",
      );
      assert(output.error.includes("before retrying"), "Correct error wording");
      assert(
        !JSON.stringify(output).includes("raw-sensitive-error"),
        "No SDK internals leaked",
      );
    });
  }
}

Deno.test("Suspended verified caller is rejected using Auth Admin ban state", async () => {
  const f = fake("admin", true, true);
  const response = await handleRequest(
    req({ action: "list" }),
    f.factory,
    legacyEnvironment,
  );
  assert(
    response.status === 401 && f.reads() === 0,
    "Banned JWT cannot access profiles/actions",
  );
});

// Supabase Edge Function: send-notification
//
// Sends an FCM push notification to every device of a given user using the
// Firebase Cloud Messaging HTTP v1 API directly (no firebase-admin npm
// dependency — the firebase-admin package's dependency chain is known to fail
// to boot in Deno edge runtimes).
//
// The function signs a short-lived Google OAuth JWT with the service account's
// private key (Web Crypto, built into Deno), exchanges it for an access token,
// then POSTs each message to FCM.
//
// The app calls this via NotificationService.sendToUser() / sendToRole() /
// sendToWorkerId() — e.g. "new task assigned", "proof submitted", "complaint
// resolved", or the Head's broadcast to all citizens.
//
// DEPLOYMENT (one-time, after supabase_setup.sql has been run):
//   1. Firebase Console -> Project settings -> Service accounts ->
//      "Generate new private key" (any language — the JSON is identical)
//   2. supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat <your-firebase-adminsdk.json>)"
//   3. supabase functions deploy send-notification
//
// Request body — exactly ONE recipient selector is required, plus message:
//   { "userId": "<supabase auth user uuid>", "title": "...", "body": "..." }
//   { "role": "citizen|worker|head", ... }   -> everyone with that role
//   { "workerId": "WK-1002", ... }           -> the worker with that ID
//   Optional: "route": "screen|id" (e.g. "task|<taskId>") for tap routing.
//
// Every push is ALSO stored in the `notifications` table (one row per
// recipient) so users can view/clear their in-app notification history.

import { createClient } from "jsr:@supabase/supabase-js@2";

const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const serviceAccountJson = FIREBASE_SERVICE_ACCOUNT;
    if (!serviceAccountJson) {
      return json(
        { error: "FIREBASE_SERVICE_ACCOUNT secret is not configured." },
        500,
      );
    }
    const serviceAccount = JSON.parse(serviceAccountJson);

    const { userId, role, workerId, title, body, route } = await req.json();
    if (!title || !body) {
      return json({ error: "title and body are required." }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { persistSession: false } },
    );

    // Resolve the recipient user id(s) -> device tokens.
    let query = supabase.from("device_tokens").select("user_id, token");
    let userIds: string[] = [];
    if (userId) {
      userIds = [userId];
      query = query.eq("user_id", userId);
    } else if (role) {
      const { data: profiles } = await supabase
        .from("profiles")
        .select("id")
        .eq("role", role);
      userIds = (profiles ?? []).map((p) => p.id as string);
      if (userIds.length === 0) {
        return json({ message: "No users with this role." });
      }
      query = query.in("user_id", userIds);
    } else if (workerId) {
      const { data: profile } = await supabase
        .from("profiles")
        .select("id")
        .eq("worker_id", workerId.toUpperCase())
        .maybeSingle();
      if (!profile) {
        return json({ message: "No profile for this worker ID." });
      }
      userIds = [profile.id as string];
      query = query.eq("user_id", profile.id as string);
    } else {
      return json({ error: "userId, role or workerId is required." }, 400);
    }

    const { data: rows, error: dbError } = await query;
    if (dbError) {
      return json({ error: dbError.message }, 500);
    }
    const tokens = (rows ?? []).map((r) => r.token as string);

    // Store the notification history (one row per recipient) so users can see
    // it in Profile -> Notifications even if their device was offline.
    if (userIds.length > 0) {
      const historyRows = userIds.map((uid) => ({
        user_id: uid,
        title,
        body,
        route: route ?? null,
      }));
      const { error: historyError } = await supabase
        .from("notifications")
        .insert(historyRows);
      if (historyError) {
        console.error("notification history insert failed:", historyError.message);
      }
    }

    if (tokens.length === 0) {
      return json({ message: "No device tokens for this user (history recorded)." });
    }

    // Sign a JWT with the service account private key and exchange it for a
    // short-lived OAuth access token.
    const accessToken = await getAccessToken(serviceAccount);

    const results = [];
    for (const token of tokens) {
      try {
        const res = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title, body },
                data: route ? { route } : {},
                android: { priority: "high" },
              },
            }),
          },
        );
        const ok = res.ok;
        const errText = ok ? "" : await res.text();
        results.push({ ok, error: ok ? null : errText.slice(0, 300) });
      } catch (e) {
        results.push({ ok: false, error: String(e) });
      }
    }

    return json({
      message: `Sent to ${tokens.length} device(s).`,
      results,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

// ---------------------------------------------------------------------------
// Google OAuth2 JWT -> access token (FCM HTTP v1 requires a bearer token).
// ---------------------------------------------------------------------------

async function getAccessToken(sa: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(
    JSON.stringify({ alg: "RS256", typ: "JWT" }),
  );
  const claims = base64UrlEncode(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const signingInput = `${header}.${claims}`;
  const signature = await signRS256(signingInput, sa.private_key);
  const jwt = `${signingInput}.${signature}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!res.ok || !data.access_token) {
    throw new Error(`OAuth token exchange failed: ${JSON.stringify(data)}`);
  }
  return data.access_token as string;
}

// Signs the JWT payload with RS256 using the service account private key
// (PKCS#8 PEM) via Deno's built-in Web Crypto.
async function signRS256(data: string, privateKeyPem: string): Promise<string> {
  const pemBody = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const der = base64ToBytes(pemBody);

  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(data),
  );
  return base64UrlBytes(new Uint8Array(signature));
}

function base64UrlEncode(text: string): string {
  return btoa(text).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64ToBytes(b64: string): Uint8Array {
  const normalized = b64.replace(/-/g, "+").replace(/_/g, "/");
  const pad = normalized.length % 4 === 0 ? "" : "=".repeat(4 - normalized.length % 4);
  const binary = atob(normalized + pad);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

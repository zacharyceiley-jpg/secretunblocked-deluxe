import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ success: false }, 405);

  const secret = Deno.env.get("TURNSTILE_SECRET");
  if (!secret) {
    console.error("TURNSTILE_SECRET is not configured");
    return json({ success: false, error: "verification_unavailable" }, 503);
  }

  let body: { token?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ success: false }, 400);
  }

  const token = typeof body.token === "string" ? body.token : "";
  if (!token || token.length > 2048) return json({ success: false }, 400);

  let result: {
    success?: boolean;
    hostname?: string;
    action?: string;
  };
  try {
    const form = new URLSearchParams({
      secret,
      response: token,
    });
    const response = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: form,
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new Error("Siteverify request failed");
    result = await response.json();
  } catch (error) {
    console.error("Turnstile Siteverify request failed", error);
    return json({ success: false }, 502);
  }

  const valid =
    result.success === true &&
    result.hostname === "secretunblocked-deluxe.zachary-ceiley.workers.dev" &&
    result.action === "community_entry";

  if (!valid) return json({ success: false }, 403);
  return json({ success: true });
});

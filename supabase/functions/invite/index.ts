import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const shortCode = url.pathname.split("/").pop();

    if (!shortCode) {
      return new Response("Missing invite code", {
        status: 400,
        headers: corsHeaders,
      });
    }

    // Create Supabase client with service role for database access
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Look up the short code
    const { data: link, error: linkError } = await supabase
      .from("guest_links")
      .select("guest_token, is_active, scan_count")
      .eq("short_code", shortCode)
      .single();

    if (linkError || !link) {
      return new Response("Invite not found", {
        status: 404,
        headers: {
          ...corsHeaders,
          "Content-Type": "text/html",
        },
      });
    }

    // Check if link is active
    if (!link.is_active) {
      return new Response(
        `<html><body><h2>Ce lien d'invitation a été désactivé.</h2></body></html>`,
        {
          status: 403,
          headers: {
            ...corsHeaders,
            "Content-Type": "text/html; charset=utf-8",
          },
        }
      );
    }

    // Increment scan count (fire and forget)
    supabase
      .from("guest_links")
      .update({
        scan_count: (link.scan_count ?? 0) + 1,
        last_scanned_at: new Date().toISOString(),
      })
      .eq("short_code", shortCode)
      .then(() => {});

    // Get the app URL from env or fallback
    const appUrl =
      Deno.env.get("APP_URL") ?? `${supabaseUrl.replace(".supabase.co", "")}.vercel.app`;

    // Redirect to the Flutter app with the full token
    const redirectUrl = `${appUrl}/#/guest/${link.guest_token}`;

    return Response.redirect(redirectUrl, 302);
  } catch (error) {
    console.error("Invite redirect error:", error);
    return new Response("Internal server error", {
      status: 500,
      headers: corsHeaders,
    });
  }
});

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get auth token from request
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response("Unauthorized", {
        status: 401,
        headers: corsHeaders,
      });
    }

    // Verify the user is authenticated
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response("Unauthorized", {
        status: 401,
        headers: corsHeaders,
      });
    }

    // Get all guest links with analytics
    const { data: links, error } = await supabase
      .from("guest_links")
      .select(
        `
        id,
        short_code,
        guest_token,
        is_active,
        scan_count,
        last_scanned_at,
        created_at,
        guests!inner(full_name, status)
      `
      )
      .order("created_at", ascending: false);

    if (error) {
      throw error;
    }

    // Calculate stats
    const totalLinks = links?.length ?? 0;
    const activeLinks = links?.filter((l) => l.is_active).length ?? 0;
    const totalScans = links?.reduce((sum, l) => sum + (l.scan_count ?? 0), 0) ?? 0;
    const scannedAtLeastOnce = links?.filter((l) => (l.scan_count ?? 0) > 0).length ?? 0;

    return new Response(
      JSON.stringify({
        stats: {
          totalLinks,
          activeLinks,
          totalScans,
          scannedAtLeastOnce,
          conversionRate:
            totalLinks > 0
              ? Math.round((scannedAtLeastOnce / totalLinks) * 100)
              : 0,
        },
        links: links ?? [],
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error) {
    console.error("Analytics error:", error);
    return new Response("Internal server error", {
      status: 500,
      headers: corsHeaders,
    });
  }
});

import { createClient } from 'jsr:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const admin = createClient(supabaseUrl, serviceRoleKey);

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Vérifier l'authentification
    const authHeader = request.headers.get('Authorization');
    if (!authHeader) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await admin.auth.getUser(token);

    if (authError || !user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    // Récupérer tous les liens avec stats
    const { data: links, error } = await admin
      .from('guest_links')
      .select(`
        id,
        short_code,
        guest_token,
        is_active,
        scan_count,
        last_scanned_at,
        created_at,
        guests!inner (full_name, status)
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;

    const totalLinks       = links?.length ?? 0;
    const activeLinks      = links?.filter((l) => l.is_active).length ?? 0;
    const totalScans       = links?.reduce((sum, l) => sum + (l.scan_count ?? 0), 0) ?? 0;
    const scannedAtLeastOnce = links?.filter((l) => (l.scan_count ?? 0) > 0).length ?? 0;

    return json({
      stats: {
        totalLinks,
        activeLinks,
        totalScans,
        scannedAtLeastOnce,
        conversionRate: totalLinks > 0
          ? Math.round((scannedAtLeastOnce / totalLinks) * 100)
          : 0,
      },
      links: links ?? [],
    });
  } catch (err) {
    console.error('Analytics error:', err);
    return json({ error: 'Internal server error' }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

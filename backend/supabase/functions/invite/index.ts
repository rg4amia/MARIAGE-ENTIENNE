import { createClient } from 'jsr:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const appUrl = Deno.env.get('APP_URL') ?? '';

const admin = createClient(supabaseUrl, serviceRoleKey);

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const url = new URL(request.url);
    const shortCode = url.pathname.split('/').pop();

    if (!shortCode) {
      return new Response('Missing invite code', { status: 400, headers: corsHeaders });
    }

    const { data: link, error } = await admin
      .from('guest_links')
      .select('guest_token, is_active, scan_count')
      .eq('short_code', shortCode)
      .single();

    if (error || !link) {
      return new Response('Invite not found', {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'text/html' },
      });
    }

    if (!link.is_active) {
      return new Response(
        `<html><body><h2>Ce lien d'invitation a été désactivé.</h2></body></html>`,
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' } },
      );
    }

    // Incrémenter le compteur de scans (fire and forget)
    admin
      .from('guest_links')
      .update({
        scan_count: (link.scan_count ?? 0) + 1,
        last_scanned_at: new Date().toISOString(),
      })
      .eq('short_code', shortCode)
      .then(() => {});

    // Rediriger vers l'app Flutter avec le token complet
    const redirectUrl = `${appUrl}/#/guest/${link.guest_token}`;
    return Response.redirect(redirectUrl, 302);
  } catch (err) {
    console.error('Invite redirect error:', err);
    return new Response('Internal server error', { status: 500, headers: corsHeaders });
  }
});

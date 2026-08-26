import { createClient } from 'jsr:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const guestPortalUrl = Deno.env.get('GUEST_PORTAL_URL') ??
  `${supabaseUrl}/functions/v1/guest-portal`;

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

    const { data: guestToken, error } = await admin.rpc('resolve_guest_link', {
      p_short_code: shortCode,
    });

    if (error || !guestToken) {
      return new Response('Invite not found', {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'text/html' },
      });
    }

    // Le portail Supabase est l'unique expérience invitée.
    const redirectUrl = `${guestPortalUrl}?token=${encodeURIComponent(guestToken)}`;
    return Response.redirect(redirectUrl, 302);
  } catch (err) {
    console.error('Invite redirect error:', err);
    return new Response('Internal server error', { status: 500, headers: corsHeaders });
  }
});

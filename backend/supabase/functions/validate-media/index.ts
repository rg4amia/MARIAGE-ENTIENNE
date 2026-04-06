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
    const payload = await request.json();
    const submissionId = payload.submission_id as string | undefined;
    const serverDurationSeconds = payload.server_duration_seconds as number | undefined;
    const validationNotes =
      (payload.validation_notes as string | undefined) ??
      'Validation serveur executee via Edge Function.';

    if (!submissionId) {
      return json({ error: 'submission_id is required' }, 400);
    }

    const { data, error } = await admin.rpc('validate_media_submission', {
      p_submission_id: submissionId,
      p_server_duration_seconds: serverDurationSeconds,
      p_notes: validationNotes,
    });

    if (error) {
      return json({ error: error.message }, 500);
    }

    return json({
      success: true,
      result: data,
      note:
          'La validation serveur confirme la regle des 30 secondes. Un controle de metadata plus avance peut etre ajoute ulterieurement.',
    });
  } catch (error) {
    return json({ error: `${error}` }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

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
    const url = new URL(request.url);
    const token = url.searchParams.get('token') ??
        (request.method === 'POST'
            ? (await request.json()).token
            : null);

    if (!token) {
      return json({ error: 'Missing token' }, 400);
    }

    const { data, error } = await admin
        .from('invitations')
        .select(`
          id,
          invitation_code,
          web_url,
          deep_link,
          is_unlocked,
          png_storage_path,
          pdf_storage_path,
          guests:guest_id (
            id,
            full_name,
            status
          ),
          seating_tables:table_id (
            label
          ),
          chairs:chair_id (
            chair_number
          ),
          guest_media_submissions (
            id,
            media_type,
            client_duration_seconds,
            server_duration_seconds,
            client_validated,
            server_validated,
            submitted_at
          )
        `)
        .eq('qr_payload', `https://mariage-entienne.app/guest/${token}`)
        .maybeSingle();

    if (error || data == null) {
      return json({ error: 'Invitation not found' }, 404);
    }

    const response = {
      invitation: data,
      signed_png_url: data.is_unlocked && data.png_storage_path
          ? await createSignedUrl('invitation-cards-png', data.png_storage_path)
          : null,
      signed_pdf_url: data.is_unlocked && data.pdf_storage_path
          ? await createSignedUrl('invitation-cards-pdf', data.pdf_storage_path)
          : null,
    };

    return json(response);
  } catch (error) {
    return json({ error: `${error}` }, 500);
  }
});

async function createSignedUrl(bucket: string, path: string) {
  const bucketPath = path.replace(`${bucket}/`, '');
  const { data } = await admin.storage.from(bucket).createSignedUrl(bucketPath, 60 * 10);
  return data?.signedUrl ?? null;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

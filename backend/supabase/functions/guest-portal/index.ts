import { createClient } from 'jsr:@supabase/supabase-js@2';
import { detectMediaDuration } from '../_shared/media-duration.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const publicPortalUrl = Deno.env.get('GUEST_PORTAL_URL') ??
  'https://rg4amia.github.io/MARIAGE-ENTIENNE/';

const admin = createClient(supabaseUrl, serviceRoleKey);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const path = url.pathname;

  // ── API routes ──────────────────────────────────────────────────────────────

  // GET /guest-portal/api/invitation?token=xxx
  if (req.method === 'GET' && path.endsWith('/api/invitation')) {
    const token = url.searchParams.get('token');
    if (!token) return apiError('Missing token', 400);

    const data = await admin.rpc('get_invitation_by_token', { p_token: token });
    if (data.error || !data.data) return apiError('Invitation introuvable', 404);

    return apiJson(data.data);
  }

  // POST /guest-portal/api/upload-url  { token, media_type, file_name, mime_type }
  if (req.method === 'POST' && path.endsWith('/api/upload-url')) {
    const body = await req.json();
    const { token, media_type, file_name, mime_type } = body;
    if (!token || !media_type || !file_name) return apiError('Paramètres manquants', 400);
    if (!['audio', 'video'].includes(media_type)) return apiError('Type de média invalide', 400);

    const extension = file_name.split('.').pop()?.toLowerCase() ?? '';
    if (!['webm', 'mp4', 'm4a', 'wav'].includes(extension)) {
      return apiError('Format de média non autorisé', 400);
    }

    // Retrouver le guest
    const { data: guest } = await admin
      .from('guests')
      .select('id, event_id')
      .eq('qr_token', token)
      .single();
    if (!guest) return apiError('Invité introuvable', 404);

    const storagePath = `${guest.event_id}/${guest.id}/${crypto.randomUUID()}.${extension}`;

    const { data: signed, error } = await admin.storage
      .from('guest-media')
      .createSignedUploadUrl(storagePath);

    if (error || !signed) return apiError('Impossible de créer l\'URL d\'upload', 500);

    return apiJson({ signed_url: signed.signedUrl, storage_path: storagePath });
  }

  // POST /guest-portal/api/submit  { token, media_type, storage_path, duration, mime_type }
  if (req.method === 'POST' && path.endsWith('/api/submit')) {
    const body = await req.json();
    const { token, media_type, storage_path, duration, mime_type } = body;
    if (!token || !media_type || !storage_path || duration == null) {
      return apiError('Paramètres manquants', 400);
    }
    if (!['audio', 'video'].includes(media_type)) return apiError('Type de média invalide', 400);

    const { data: guest, error: guestError } = await admin
      .from('guests')
      .select('id, event_id')
      .eq('qr_token', token)
      .single();
    if (guestError || !guest) return apiError('Invité introuvable', 404);
    const expectedPrefix = `${guest.event_id}/${guest.id}/`;
    if (!storage_path.startsWith(expectedPrefix)) {
      return apiError('Chemin de média invalide pour cette invitation', 403);
    }

    const { data: mediaBlob, error: downloadError } = await admin.storage
      .from('guest-media')
      .download(storage_path);
    if (downloadError || !mediaBlob) return apiError('Média uploadé introuvable', 422);
    if (mediaBlob.size > 50 * 1024 * 1024) {
      await admin.storage.from('guest-media').remove([storage_path]);
      return apiError('Le média dépasse la taille maximale de 50 Mo', 413);
    }

    const mediaBytes = new Uint8Array(await mediaBlob.arrayBuffer());
    const serverDuration = detectMediaDuration(mediaBytes, mime_type ?? mediaBlob.type);
    if (serverDuration == null) {
      await admin.storage.from('guest-media').remove([storage_path]);
      return apiError('La durée réelle du média ne peut pas être vérifiée', 422);
    }
    if (serverDuration < 30) {
      await admin.storage.from('guest-media').remove([storage_path]);
      return apiError(`Le média dure ${Math.floor(serverDuration)} secondes; 30 secondes sont requises`, 422);
    }
    if (Math.abs(serverDuration - Number(duration)) > 5) {
      await admin.storage.from('guest-media').remove([storage_path]);
      return apiError('La durée déclarée ne correspond pas au fichier envoyé', 422);
    }

    const { data, error } = await admin.rpc('submit_guest_media_by_token', {
      p_token: token,
      p_media_type: media_type,
      p_storage_path: storage_path,
      p_client_duration_seconds: duration,
      p_server_duration_seconds: serverDuration,
      p_mime_type: mime_type ?? null,
    });

    if (error) return apiError(error.message, 500);
    return apiJson(data);
  }

  // GET /guest-portal/api/card-url?token=xxx
  if (req.method === 'GET' && path.endsWith('/api/card-url')) {
    const token = url.searchParams.get('token');
    if (!token) return apiError('Missing token', 400);

    const { data: inv } = await admin.rpc('get_invitation_by_token', { p_token: token });
    if (!inv) return apiError('Invitation introuvable', 404);

    const urls: Record<string, string | null> = { png: null, pdf: null };

    if (inv.is_unlocked && inv.png_storage_path) {
      const { data } = await admin.storage
        .from('invitation-cards-png')
        .createSignedUrl(inv.png_storage_path.replace('invitation-cards-png/', ''), 3600);
      urls.png = data?.signedUrl ?? null;
    }
    if (inv.is_unlocked && inv.pdf_storage_path) {
      const { data } = await admin.storage
        .from('invitation-cards-pdf')
        .createSignedUrl(inv.pdf_storage_path.replace('invitation-cards-pdf/', ''), 3600);
      urls.pdf = data?.signedUrl ?? null;
    }

    return apiJson({ ...inv, signed_png_url: urls.png, signed_pdf_url: urls.pdf });
  }

  // GET /guest-portal/api/entrance?code=xxx
  if (req.method === 'GET' && path.endsWith('/api/entrance')) {
    const code = url.searchParams.get('code');
    if (!code) return apiError('Code d’entrée manquant', 400);
    const { data, error } = await admin.rpc('resolve_entrance_code', { p_code: code });
    if (error || !data) return apiError('QR d’entrée invalide ou désactivé', 404);
    return apiJson(data);
  }

  // POST /guest-portal/api/check-in { entrance_code, invitation_identifier }
  if (req.method === 'POST' && path.endsWith('/api/check-in')) {
    const body = await req.json();
    const entranceCode = String(body.entrance_code ?? '').trim();
    const invitationIdentifier = String(body.invitation_identifier ?? '').trim();
    if (!entranceCode || !invitationIdentifier) return apiError('Informations manquantes', 400);
    const { data, error } = await admin.rpc('check_in_guest', {
      p_entrance_code: entranceCode,
      p_invitation_identifier: invitationIdentifier,
    });
    if (error) {
      const message = error.message.includes('must be unlocked')
        ? 'Votre carte doit être débloquée avant l’entrée.'
        : error.message.includes('not found')
        ? 'Invitation introuvable.'
        : 'Impossible de valider votre entrée.';
      return apiError(message, 422);
    }
    return apiJson(data);
  }

  // GET /guest-portal/api/shell?token=xxx&entrance=xxx
  // Supabase's *.supabase.co gateway deliberately serves HTML responses as
  // text/plain. The public static host loads the shell through this JSON route,
  // while all sensitive operations remain handled by this Edge Function.
  if (req.method === 'GET' && path.endsWith('/api/shell')) {
    const token = url.searchParams.get('token') ?? '';
    const entranceCode = url.searchParams.get('entrance') ?? '';
    return apiJson({ html: renderSPA(token, entranceCode, supabaseUrl) });
  }

  // ── PWA: manifest.json ──────────────────────────────────────────────────────
  if (req.method === 'GET' && path.endsWith('/manifest.json')) {
    // Base path — Edge Runtime strips /functions/v1/ from pathname
    const basePath = '/functions/v1/guest-portal/';
    return new Response(JSON.stringify({
      name: 'Invitation de Mariage',
      short_name: 'Mariage',
      description: 'Votre carte d\'invitation de mariage interactif',
      start_url: url.origin + basePath,
      display: 'standalone',
      background_color: '#1a1a2e',
      theme_color: '#c9a84c',
      orientation: 'portrait',
      icons: [
        { src: url.origin + basePath + 'icon-192.png', sizes: '192x192', type: 'image/svg+xml', purpose: 'any maskable' },
        { src: url.origin + basePath + 'icon-512.png', sizes: '512x512', type: 'image/svg+xml', purpose: 'any maskable' },
      ],
      categories: ['social', 'entertainment'],
      lang: 'fr',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/manifest+json', 'Cache-Control': 'public, max-age=86400' },
    });
  }

  // ── PWA: service worker ─────────────────────────────────────────────────────
  if (req.method === 'GET' && path.endsWith('/sw.js')) {
    return new Response(renderServiceWorker(), {
      headers: { ...corsHeaders, 'Content-Type': 'application/javascript', 'Cache-Control': 'no-cache' },
    });
  }

  // ── PWA: icons (inline SVG → PNG placeholder) ──────────────────────────────
  if (req.method === 'GET' && /icon-(192|512)\.png$/.test(path)) {
    const size = path.endsWith('icon-192.png') ? 192 : 512;
    return new Response(renderIconSVG(size), {
      headers: { ...corsHeaders, 'Content-Type': 'image/svg+xml', 'Cache-Control': 'public, max-age=604800' },
    });
  }

  // ── Public portal compatibility redirect ───────────────────────────────────
  // Existing QR codes still target this Edge Function. Keep them valid while
  // serving the browser UI from a host that is allowed to return text/html.
  const redirectUrl = new URL(publicPortalUrl);
  for (const [key, value] of url.searchParams) {
    redirectUrl.searchParams.set(key, value);
  }
  return Response.redirect(redirectUrl, 302);
});

// ── Helpers ──────────────────────────────────────────────────────────────────

function apiJson(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function apiError(msg: string, status = 400) {
  return new Response(JSON.stringify({ error: msg }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function inlineScriptValue(value: string): string {
  return JSON.stringify(value)
    .replaceAll('<', '\\u003c')
    .replaceAll('>', '\\u003e')
    .replaceAll('&', '\\u0026')
    .replaceAll('\u2028', '\\u2028')
    .replaceAll('\u2029', '\\u2029');
}

// ── Heroicons (inlined SVG, outline unless noted) ──────────────────────────────
const ARROW_LEFT_ICON =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" /></svg>';
const PAPER_AIRPLANE_ICON =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 12 3.269 3.126A59.768 59.768 0 0 1 21.485 12 59.77 59.77 0 0 1 3.27 20.876L5.999 12Zm0 0h7.5" /></svg>';
// Solid record dot / stop square — no direct Heroicons equivalent, drawn to match their 24x24 solid style.
const RECORD_ICON = '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="9" /></svg>';

// ── SPA HTML/CSS/JS inline ───────────────────────────────────────────────────

function renderSPA(initialToken: string, initialEntranceCode: string, supabaseUrl: string): string {
  return /* html */`<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Mon Invitation de Mariage</title>

  <!-- PWA meta tags -->
  <meta name="theme-color" content="#c9a84c" />
  <meta name="apple-mobile-web-app-capable" content="yes" />
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
  <meta name="apple-mobile-web-app-title" content="Mariage" />
  <meta name="description" content="Votre carte d\'invitation de mariage interactif" />
  <meta name="mobile-web-app-capable" content="yes" />
  <link rel="manifest" href="./manifest.json" />
  <link rel="apple-touch-icon" href="./icon-192.png" />
  <link rel="icon" type="image/svg+xml" href="./icon-192.png" />
  <style>
    /* ── Reset & base ── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --gold:   #D4AF37;
      --gold2:  #e0bf52;
      --orange: #FF7A3D;
      --salmon: #FF8F7E;
      --peach:  #FFD6B3;
      --ivory:  #FFF7ED;

      --dark:   #4A3B32;
      --card:   #ffffff;
      --text:   #5C4D44;
      --muted:  #9C8A80;
      --danger: #e74c3c;
      --success:#27ae60;
      --radius: 24px;
      --shadow: 0 12px 36px rgba(255, 122, 61, 0.15);
      --bg-gradient: linear-gradient(135deg, #FFF7ED 0%, #FFD6B3 100%);
      --timer-bg: #FFEAD9;
      --step-bg: #FFEAD9;
      --input-border: #FFD6B3;
      --tab-bg: #FFF7ED;
      --tab-selected-bg: #FFE5CE;
    }

    @media (prefers-color-scheme: light) {
      /* Theme is forced to light/floral for both modes to keep the wedding vibe */
    }

    html, body {
      min-height: 100%;
      font-family: 'Georgia', serif;
      background: var(--bg-gradient);
      color: var(--text);
      transition: background 0.6s ease, color 0.3s ease;
    }

    /* ── Layout ── */
    #app {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px 16px;
    }

    .screen { display: none; width: 100%; max-width: 480px; }
    .screen.active { display: flex; flex-direction: column; gap: 20px; animation: fadeIn .4s ease; }

    @keyframes fadeIn { from { opacity:0; transform:translateY(16px); } to { opacity:1; transform:none; } }

    /* ── Card ── */
    .card {
      background: var(--card);
      border-radius: var(--radius);
      padding: 28px 24px;
      box-shadow: var(--shadow);
    }

    /* ── Header ── */
    .header {
      text-align: center;
      padding: 20px 0 4px;
    }
    .header .rings { font-size: 40px; margin-bottom: 8px; }
    .header h1 {
      font-size: 26px;
      color: var(--orange);
      font-weight: normal;
      letter-spacing: 1px;
    }
    .header p { color: var(--muted); font-size: 13px; margin-top: 4px; }

    /* ── Guest info ── */
    .guest-name {
      font-size: 26px;
      font-weight: bold;
      color: var(--dark);
      text-align: center;
      margin-bottom: 6px;
    }
    .guest-meta {
      display: flex;
      justify-content: center;
      gap: 20px;
      flex-wrap: wrap;
    }
    .badge {
      background: linear-gradient(135deg, var(--orange), #E6662E);
      color: #fff;
      border-radius: 50px;
      padding: 6px 16px;
      font-size: 13px;
      font-weight: 600;
      letter-spacing: .5px;
    }

    /* ── Steps ── */
    .steps {
      display: flex;
      justify-content: center;
      gap: 8px;
      margin: 4px 0;
    }
    .step {
      width: 32px; height: 32px;
      border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
      font-size: 13px; font-weight: bold;
      background: var(--step-bg); color: var(--muted);
      transition: all .3s;
    }
    .step.done  { background: var(--success); color: #fff; }
    .step.active{ background: var(--orange);    color: #fff; }
    .step-line  { flex: 1; height: 2px; background: var(--step-bg); margin-top: 15px; max-width: 40px; }
    .step-line.done { background: var(--success); }

    /* ── Section title ── */
    .section-title {
      font-size: 17px;
      font-weight: bold;
      color: var(--dark);
      margin-bottom: 4px;
    }
    .section-sub {
      font-size: 13px;
      color: var(--muted);
      margin-bottom: 16px;
    }

    /* ── Media type selector ── */
    .media-tabs {
      display: flex;
      gap: 10px;
      margin-bottom: 16px;
    }
    .btn-record { transition: all .15s cubic-bezier(0.4, 0, 0.2, 1); }
    .media-tab {
      flex: 1;
      padding: 12px;
      border: 2px solid var(--input-border);
      border-radius: 16px;
      background: var(--tab-bg);
      cursor: pointer;
      text-align: center;
      font-size: 14px;
      transition: all .2s;
    }
    .media-tab:hover { border-color: var(--orange); }
    .media-tab.selected { border-color: var(--orange); background: var(--tab-selected-bg); }
    .media-tab .icon { width: 28px; height: 28px; margin: 0 auto 4px; color: var(--muted); transition: color .2s; }
    .media-tab .icon svg { width: 100%; height: 100%; display: block; }
    .media-tab.selected .icon { color: var(--orange); }
    .media-tab .label { font-weight: 600; color: var(--dark); }
    .media-tab .desc  { font-size: 11px; color: var(--muted); margin-top: 2px; }

    /* ── Recording UI ── */
    #recorder-area { display: none; flex-direction: column; align-items: center; gap: 16px; }
    #recorder-area.visible { display: flex; }

    #preview-video, #preview-audio-wrap {
      width: 100%; border-radius: 12px; overflow: hidden;
      background: #000; display: none;
    }
    #preview-video { max-height: 240px; object-fit: cover; }
    #preview-audio-wrap { padding: 16px; display: none; align-items: center; justify-content: center; }
    #preview-audio-wrap audio { width: 100%; }

    /* Timer ring */
    .timer-wrap {
      display: flex; flex-direction: column; align-items: center; gap: 6px;
    }
    .timer-ring { position: relative; width: 100px; height: 100px; }
    .timer-ring svg { transform: rotate(-90deg); }
    .timer-ring circle { fill: none; stroke-width: 8; }
    .timer-ring .bg   { stroke: var(--timer-bg); }
    .timer-ring .prog { stroke: var(--orange); stroke-linecap: round; transition: stroke-dashoffset 0.1s cubic-bezier(0.4, 0, 0.2, 1); }
    .timer-ring .prog.done { stroke: var(--success); transition: stroke 0.4s ease; }
    .timer-ring .glow { filter: drop-shadow(0 0 6px var(--orange)); transition: filter 0.4s; }
    .timer-ring .glow.done { filter: drop-shadow(0 0 8px var(--success)); }
    @keyframes timerPulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.06); }
    }
    .timer-wrap.recording .timer-ring { animation: timerPulse 2s ease-in-out infinite; }
    .timer-text {
      position: absolute; inset: 0;
      display: flex; align-items: center; justify-content: center;
      font-size: 22px; font-weight: bold; color: var(--dark);
    }
    .timer-label { font-size: 12px; color: var(--muted); }

    /* Record button */
    .btn-record {
      width: 72px; height: 72px; border-radius: 50%;
      border: 4px solid var(--orange);
      background: #fff;
      cursor: pointer;
      display: flex; align-items: center; justify-content: center;
      color: var(--orange);
      transition: all .2s;
      box-shadow: 0 4px 12px rgba(0,0,0,.1);
    }
    #btn-record-icon { width: 28px; height: 28px; display: block; }
    #btn-record-icon svg { width: 100%; height: 100%; display: block; }
    .btn-record:hover { transform: scale(1.05); }
    .btn-record.recording { background: var(--danger); border-color: var(--danger); color: #fff; animation: pulse 1.2s infinite; }
    @keyframes pulse { 0%,100%{box-shadow:0 0 0 0 rgba(231,76,60,.4);} 50%{box-shadow:0 0 0 12px rgba(231,76,60,0);} }

    .rec-hint { font-size: 12px; color: var(--muted); text-align: center; }

    /* ── Progress bar ── */
    .progress-wrap { background: #eee; border-radius: 50px; height: 6px; overflow: hidden; }
    .progress-bar  { height: 100%; background: linear-gradient(90deg, var(--orange), var(--salmon)); border-radius: 50px; transition: width .3s; }

    /* ── Buttons ── */
    .btn {
      width: 100%; padding: 16px 24px;
      border: none; border-radius: 50px;
      font-size: 16px; font-weight: bold; cursor: pointer;
      transition: all .2s; letter-spacing: 0.5px;
      display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    }
    .btn svg { width: 20px; height: 20px; flex-shrink: 0; }
    .btn-primary { background: linear-gradient(135deg, var(--orange), #E6662E); color: #fff; box-shadow: 0 4px 15px rgba(255,122,61,0.25); }
    .btn-primary:hover { opacity: .9; transform: translateY(-1px); box-shadow: 0 6px 20px rgba(255,122,61,0.3); }
    .btn-primary:disabled { opacity: .5; cursor: not-allowed; transform: none; box-shadow: none; }
    .btn-outline { background: var(--card); border: 2px solid var(--orange); color: var(--orange); }
    .btn-outline:hover { background: var(--tab-selected-bg); }

    .text-input {
      width: 100%;
      padding: 14px 16px;
      border: 2px solid var(--input-border);
      border-radius: 12px;
      font: inherit;
      font-size: 16px;
      text-transform: uppercase;
      outline: none;
      margin-bottom: 12px;
    }
    .text-input:focus { border-color: var(--gold); }

    /* ── Card invitation ── */
    .invitation-card {
      background: var(--ivory);
      border-radius: 20px; padding: 40px 24px;
      text-align: center; color: var(--dark);
      border: 2px solid var(--peach);
      box-shadow: inset 0 0 20px rgba(255,122,61,0.05);
    }
    .invitation-card .couple { font-size: 32px; color: var(--orange); margin: 8px 0 16px; letter-spacing: 1px; }
    .invitation-card .divider { border: none; border-top: 1px solid var(--peach); margin: 16px 0; }
    .invitation-card .inv-name { font-size: 28px; font-weight: bold; margin: 8px 0; color: var(--dark); }
    .invitation-card .inv-detail { font-size: 15px; color: var(--text); margin: 6px 0; }
    .invitation-card .inv-code {
      font-size: 12px; letter-spacing: 3px;
      color: var(--muted); margin-top: 24px;
    }
    .unlock-badge {
      display: inline-flex; align-items: center; gap: 6px;
      background: rgba(39,174,96,.15); border: 1px solid rgba(39,174,96,.4);
      color: #2ecc71; border-radius: 50px; padding: 6px 14px;
      font-size: 13px; margin-bottom: 8px;
    }

    /* ── Download buttons ── */
    .download-row { display: flex; gap: 10px; }
    .download-row .btn { flex: 1; }

    /* ── Alert ── */
    .alert {
      padding: 12px 16px; border-radius: 10px; font-size: 13px;
      display: none; align-items: flex-start; gap: 10px;
    }
    .alert.error   { background: #fdf0f0; color: var(--danger); border: 1px solid #f5c6c6; }
    .alert.success { background: #f0fdf4; color: var(--success); border: 1px solid #c6e9d0; }
    .alert.visible { display: flex; }
    .alert::before {
      content: ''; flex-shrink: 0; width: 18px; height: 18px; margin-top: 1px;
      background-repeat: no-repeat; background-size: contain;
    }
    .alert.error::before {
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23e74c3c'%3E%3Cpath fill-rule='evenodd' d='M9.401 3.003c1.155-2 4.043-2 5.197 0l7.355 12.748c1.154 2-.29 4.5-2.599 4.5H4.645c-2.309 0-3.752-2.5-2.598-4.5L9.4 3.003ZM12 8.25a.75.75 0 0 1 .75.75v3.75a.75.75 0 0 1-1.5 0V9a.75.75 0 0 1 .75-.75Zm0 8.25a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5Z' clip-rule='evenodd'/%3E%3C/svg%3E");
    }
    .alert.success::before {
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2327ae60'%3E%3Cpath fill-rule='evenodd' d='M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12Zm13.36-1.814a.75.75 0 1 0-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.14-.094l3.75-5.25Z' clip-rule='evenodd'/%3E%3C/svg%3E");
    }

    /* ── Loader ── */
    .loader {
      display: none; flex-direction: column; align-items: center; gap: 12px; padding: 32px;
    }
    .loader.visible { display: flex; }
    .spinner {
      width: 40px; height: 40px; border-radius: 50%;
      border: 4px solid var(--step-bg); border-top-color: var(--gold);
      animation: spin .8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .loader p { color: var(--muted); font-size: 14px; text-align: center; }

    /* ── Upload progress ── */
    #upload-status { display: none; }
    #upload-status.visible { display: block; }
  </style>
</head>
<body>
<div id="app">

  <!-- ══════ SCREEN: LOADING ══════ -->
  <div id="screen-loading" class="screen active" style="align-items:center;">
    <div class="loader visible">
      <div class="spinner"></div>
      <p>Chargement de votre invitation…</p>
    </div>
  </div>

  <!-- ══════ SCREEN: ERROR ══════ -->
  <div id="screen-error" class="screen">
    <div style="text-align:center; padding: 40px 20px;">
      <div style="font-size:60px;margin-bottom:16px;">💌</div>
      <h2 style="color:var(--dark);margin-bottom:8px;">Invitation introuvable</h2>
      <p style="color:var(--muted);font-size:14px;" id="error-msg">
        Ce lien d'invitation n'est pas valide ou a expiré.
      </p>
    </div>
  </div>

  <!-- ══════ SCREEN: ENTRANCE CHECK-IN ══════ -->
  <div id="screen-entrance" class="screen">
    <div class="header">
      <div class="rings">🎟️</div>
      <h1 id="entrance-event-title">Bienvenue au mariage</h1>
      <p id="entrance-event-location"></p>
    </div>

    <div class="card" id="entrance-form-card">
      <div class="section-title">Confirmez votre arrivée</div>
      <div class="section-sub" id="entrance-hint">
        Saisissez le code affiché sur votre carte d’invitation.
      </div>
      <input
        class="text-input"
        id="entrance-invitation-code"
        type="text"
        autocomplete="one-time-code"
        placeholder="INV-..."
      />
      <div id="alert-entrance" class="alert error"></div>
      <button class="btn btn-primary" id="btn-check-in" onclick="App.submitCheckIn()">
        ✅ Valider mon entrée
      </button>
      <button
        class="btn btn-outline"
        id="btn-another-invitation"
        style="display:none;margin-top:10px;"
        onclick="App.useAnotherInvitation()"
      >
        Utiliser une autre invitation
      </button>
    </div>

    <div class="card" id="entrance-success" style="display:none;text-align:center;">
      <div style="font-size:60px;margin-bottom:12px;">✅</div>
      <div class="unlock-badge" id="entrance-success-label">Entrée validée</div>
      <div class="guest-name" id="entrance-guest-name" style="margin-top:16px;"></div>
      <div class="guest-meta" id="entrance-guest-meta"></div>
      <p style="color:var(--muted);font-size:13px;margin-top:16px;">
        Présentez cet écran à l’équipe d’accueil si nécessaire.
      </p>
    </div>
  </div>

  <!-- ══════ SCREEN: WELCOME ══════ -->
  <div id="screen-welcome" class="screen">
    <div class="header">
      <div class="rings">💍</div>
      <h1 id="welcome-event-title">Mariage</h1>
      <p id="welcome-event-date"></p>
    </div>

    <div class="card">
      <div class="guest-name" id="welcome-name"></div>
      <div class="guest-meta" id="welcome-meta"></div>
    </div>

    <div class="card">
      <!-- Steps indicator -->
      <div class="steps" style="margin-bottom:20px;">
        <div class="step active" id="step1">1</div>
        <div class="step-line" id="line1"></div>
        <div class="step" id="step2">2</div>
        <div class="step-line" id="line2"></div>
        <div class="step" id="step3">🎉</div>
      </div>

      <div id="welcome-locked">
        <div class="section-title">Votre invitation vous attend !</div>
        <div class="section-sub">
          Pour débloquer votre carte d'invitation personnalisée, enregistrez un message
          audio ou vidéo de <strong>30 secondes minimum</strong> pour les mariés. 🎙️
        </div>
        <button class="btn btn-primary" onclick="App.goToRecord()">
          🎙️ Enregistrer mon message
        </button>
      </div>

      <div id="welcome-unlocked" style="display:none;">
        <div class="unlock-badge">✅ Message validé</div>
        <div class="section-title" style="margin-top:8px;">Votre carte est disponible !</div>
        <div class="section-sub">Votre message a été reçu. Accédez à votre carte d'invitation.</div>
        <button class="btn btn-primary" onclick="App.goToCard()">
          🎊 Voir ma carte d'invitation
        </button>
      </div>
    </div>
  </div>

  <!-- ══════ SCREEN: RECORD ══════ -->
  <div id="screen-record" class="screen">
    <div class="header">
      <div class="rings">🎙️</div>
      <h1>Votre message</h1>
      <p>Enregistrez 30 secondes minimum pour les mariés</p>
    </div>

    <div class="card">
      <!-- Media type tabs -->
      <div class="media-tabs">
        <div class="media-tab selected" id="tab-audio" onclick="App.selectMediaType('audio')">
          <div class="icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 9V4.5a.75.75 0 0 1 .955-.721l9 2.571a.75.75 0 0 1 .545.721V15a3 3 0 1 1-1.5-2.598V6.878l-7.5-2.143v9.365a3 3 0 1 1-1.5-2.598V9Z" />
            </svg>
          </div>
          <div class="label">Audio</div>
          <div class="desc">Message vocal</div>
        </div>
        <div class="media-tab" id="tab-video" onclick="App.selectMediaType('video')">
          <div class="icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="m15.75 10.5 4.72-4.72a.75.75 0 0 1 1.28.53v11.38a.75.75 0 0 1-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 0 0 2.25-2.25v-9a2.25 2.25 0 0 0-2.25-2.25h-9A2.25 2.25 0 0 0 2.25 7.5v9a2.25 2.25 0 0 0 2.25 2.25Z" />
            </svg>
          </div>
          <div class="label">Vidéo</div>
          <div class="desc">Message filmé</div>
        </div>
      </div>

      <!-- Recorder -->
      <div id="recorder-area" class="visible">
        <!-- Video preview (video mode) -->
        <video id="preview-video" autoplay muted playsinline></video>
        <!-- Audio visual (audio mode) -->
        <div id="preview-audio-wrap" style="display:flex;">
          <div style="text-align:center;width:100%;">
            <div style="width:48px;height:48px;margin:0 auto;color:var(--orange);" id="audio-idle-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 18.75a6 6 0 0 0 6-6v-1.5m-6 7.5a6 6 0 0 1-6-6v-1.5m6 7.5v3.75m-3.75 0h7.5M12 15.75a3 3 0 0 1-3-3V4.5a3 3 0 1 1 6 0v8.25a3 3 0 0 1-3 3Z" />
              </svg>
            </div>
          </div>
        </div>

        <!-- Timer ring -->
        <div class="timer-wrap">
          <div class="timer-ring">
            <svg width="100" height="100" viewBox="0 0 100 100">
              <circle class="bg"   cx="50" cy="50" r="42" />
              <circle class="prog" id="timer-circle" cx="50" cy="50" r="42"
                stroke-dasharray="264"
                stroke-dashoffset="264" />
            </svg>
            <div class="timer-text" id="timer-text">0s</div>
          </div>
          <div class="timer-label" id="timer-label">Appuyez pour commencer</div>
        </div>

        <!-- Record button -->
        <button class="btn-record" id="btn-record" onclick="App.toggleRecord()">
          <span id="btn-record-icon">${RECORD_ICON}</span>
        </button>
        <div class="rec-hint" id="rec-hint">Appuyez pour démarrer l'enregistrement</div>

        <!-- Playback area (after recording) -->
        <div id="playback-area" style="display:none;width:100%;flex-direction:column;gap:12px;">
          <video id="playback-video" controls style="width:100%;border-radius:12px;display:none;"></video>
          <audio id="playback-audio" controls style="width:100%;display:none;"></audio>
          <div class="alert success visible" id="duration-ok" style="display:none;">
            <div>Durée validée ! Votre message dure <strong id="final-duration"></strong>.</div>
          </div>
          <div class="alert error visible" id="duration-ko" style="display:none;">
            <div>Message trop court. Minimum 30 secondes requis.</div>
          </div>
        </div>
      </div>

      <div id="alert-rec" class="alert error"></div>
    </div>

    <!-- Upload progress -->
    <div class="card" id="upload-status">
      <div class="section-title" style="margin-bottom:12px;">📤 Envoi en cours…</div>
      <div class="progress-wrap"><div class="progress-bar" id="upload-bar" style="width:0%"></div></div>
      <p style="font-size:12px;color:var(--muted);margin-top:8px;" id="upload-label">Préparation…</p>
    </div>

    <div style="display:flex;gap:10px;">
      <button class="btn btn-outline" style="flex:1;" onclick="App.goToWelcome()">${ARROW_LEFT_ICON} Retour</button>
      <button class="btn btn-primary" style="flex:2;" id="btn-submit" onclick="App.submitMedia()" disabled>
        Envoyer mon message ${PAPER_AIRPLANE_ICON}
      </button>
    </div>
  </div>

  <!-- ══════ SCREEN: CARD ══════ -->
  <div id="screen-card" class="screen">
    <div class="header">
      <div class="rings">🎊</div>
      <h1>Votre carte d'invitation</h1>
      <p>Conservez-la précieusement</p>
    </div>

    <div class="invitation-card" id="inv-card">
      <div style="font-size:32px;">💍</div>
      <div class="couple" id="card-couple"></div>
      <hr class="divider" />
      <div style="font-size:13px;color:rgba(255,255,255,.5);letter-spacing:2px;">INVITE</div>
      <div class="inv-name" id="card-name"></div>
      <hr class="divider" />
      <div class="inv-detail" id="card-table"></div>
      <div class="inv-detail" id="card-chair"></div>
      <div class="inv-detail" id="card-date"></div>
      <div class="inv-detail" id="card-location"></div>
      <div class="inv-code" id="card-code"></div>
    </div>

    <div class="card">
      <div class="unlock-badge">🎊 Invitation débloquée</div>
      <div class="section-title" style="margin-top:8px;">Télécharger votre carte</div>
      <div class="section-sub">Enregistrez votre carte d'invitation ou partagez-la.</div>

      <div class="download-row" id="download-row" style="display:none;">
        <button class="btn btn-primary" id="btn-dl-png" onclick="App.downloadCard('png')">
          🖼 Image PNG
        </button>
        <button class="btn btn-outline" id="btn-dl-pdf" onclick="App.downloadCard('pdf')">
          📄 PDF
        </button>
      </div>

      <button class="btn btn-outline" style="margin-top:10px;" onclick="App.shareCard()">
        🔗 Partager le lien
      </button>
    </div>

    <button class="btn btn-outline" onclick="App.goToWelcome()">${ARROW_LEFT_ICON} Retour à l'accueil</button>
  </div>

</div><!-- #app -->

<script>
// ═══════════════════════════════════════════════════════
// CONFIG — injectée côté serveur
// ═══════════════════════════════════════════════════════
const FUNCTION_BASE = '${supabaseUrl}/functions/v1/guest-portal';

const RECORD_ICON_HTML = '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="9" /></svg>';
const STOP_ICON_HTML = '<svg viewBox="0 0 24 24" fill="currentColor"><rect x="7" y="7" width="10" height="10" rx="2" /></svg>';

// ═══════════════════════════════════════════════════════
// APP STATE
// ═══════════════════════════════════════════════════════
const State = {
  token:        ${inlineScriptValue(initialToken)},
  entranceCode: ${inlineScriptValue(initialEntranceCode)},
  entrance:    null,
  savedToken:  null,
  invitation:  null,
  mediaType:   'audio',   // 'audio' | 'video'
  stream:      null,
  recorder:    null,
  chunks:      [],
  blob:        null,
  duration:    0,
  timerStart:  null,
  timerHandle: null,
  isRecording: false,
  signedPngUrl: null,
  signedPdfUrl: null,
};

// ═══════════════════════════════════════════════════════
// SCREEN MANAGER
// ═══════════════════════════════════════════════════════
function showScreen(id) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.getElementById('screen-' + id).classList.add('active');
}

// ═══════════════════════════════════════════════════════
// API CALLS
// ═══════════════════════════════════════════════════════
async function apiFetch(path, opts = {}) {
  const res = await fetch(FUNCTION_BASE + path, {
    ...opts,
    headers: { 'Content-Type': 'application/json', ...(opts.headers ?? {}) },
  });
  if (!res.ok) {
    const e = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(e.error ?? 'Erreur réseau');
  }
  return res.json();
}

// ═══════════════════════════════════════════════════════
// INIT
// ═══════════════════════════════════════════════════════
async function init() {
  // Dynamic theme-color based on system preference
  const mq = window.matchMedia('(prefers-color-scheme: light)');
  function updateThemeColor(e) {
    const color = e.matches ? '#f5f0e8' : '#1a1a2e';
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', color);
  }
  updateThemeColor(mq);
  mq.addEventListener('change', updateThemeColor);

  State.savedToken = localStorage.getItem('wedding_invitation_token');

  if (State.entranceCode) {
    try {
      State.entrance = await apiFetch('/api/entrance?code=' + encodeURIComponent(State.entranceCode));
      renderEntrance();
      showScreen('entrance');
    } catch (e) {
      document.getElementById('error-msg').textContent = e.message;
      showScreen('error');
    }
    return;
  }

  // Token from URL param if not injected
  if (!State.token) {
    const p = new URLSearchParams(location.search);
    State.token = p.get('token') ?? '';
  }
  if (!State.token) {
    document.getElementById('error-msg').textContent = 'Aucun token d\\'invitation trouvé dans le lien.';
    showScreen('error');
    return;
  }

  try {
    State.invitation = await apiFetch('/api/invitation?token=' + encodeURIComponent(State.token));
    localStorage.setItem('wedding_invitation_token', State.token);
    renderWelcome();
    showScreen('welcome');
  } catch (e) {
    document.getElementById('error-msg').textContent = e.message;
    showScreen('error');
  }
}

function renderEntrance() {
  const entrance = State.entrance ?? {};
  document.getElementById('entrance-event-title').textContent = entrance.title ?? 'Bienvenue au mariage';
  const details = [entrance.event_date_label, entrance.location].filter(Boolean).join(' • ');
  document.getElementById('entrance-event-location').textContent = details;
  if (State.savedToken) {
    document.getElementById('entrance-hint').textContent =
      'Votre invitation a été retrouvée sur ce téléphone. Confirmez simplement votre arrivée.';
    document.getElementById('entrance-invitation-code').style.display = 'none';
    document.getElementById('btn-another-invitation').style.display = 'block';
  }
}

function useAnotherInvitation() {
  State.savedToken = null;
  localStorage.removeItem('wedding_invitation_token');
  document.getElementById('entrance-invitation-code').style.display = 'block';
  document.getElementById('entrance-invitation-code').focus();
  document.getElementById('btn-another-invitation').style.display = 'none';
  document.getElementById('entrance-hint').textContent =
    'Saisissez le code affiché sur votre carte d’invitation.';
}

async function submitCheckIn() {
  clearAlert('entrance');
  const input = document.getElementById('entrance-invitation-code').value.trim();
  const identifier = State.savedToken || input;
  if (!identifier) {
    showAlert('entrance', 'Saisissez le code de votre invitation.');
    return;
  }

  const button = document.getElementById('btn-check-in');
  button.disabled = true;
  button.textContent = 'Validation en cours…';
  try {
    const result = await apiFetch('/api/check-in', {
      method: 'POST',
      body: JSON.stringify({
        entrance_code: State.entranceCode,
        invitation_identifier: identifier,
      }),
    });
    document.getElementById('entrance-form-card').style.display = 'none';
    document.getElementById('entrance-success').style.display = 'block';
    document.getElementById('entrance-success-label').textContent =
      result.already_checked_in ? 'Arrivée déjà enregistrée' : 'Entrée validée';
    vibrate([20, 40, 20]); // check-in success haptic
    document.getElementById('entrance-guest-name').textContent = result.guest_name ?? '';
    const meta = document.getElementById('entrance-guest-meta');
    meta.replaceChildren();
    for (const label of [
      result.table_label ? '🪑 Table ' + result.table_label : null,
      result.chair_number ? '💺 Chaise ' + result.chair_number : null,
    ].filter(Boolean)) {
      const badge = document.createElement('span');
      badge.className = 'badge';
      badge.textContent = label;
      meta.appendChild(badge);
    }
  } catch (e) {
    if (State.savedToken && String(e.message).includes('introuvable')) {
      useAnotherInvitation();
    }
    showAlert('entrance', e.message);
    button.disabled = false;
    button.textContent = '✅ Valider mon entrée';
  }
}

// ═══════════════════════════════════════════════════════
// WELCOME SCREEN
// ═══════════════════════════════════════════════════════
function renderWelcome() {
  const inv = State.invitation;
  const ev  = inv.event ?? {};

  document.getElementById('welcome-event-title').textContent = ev.title ?? 'Mariage';
  document.getElementById('welcome-event-date').textContent  = ev.event_date_label ?? '';
  document.getElementById('welcome-name').textContent        = inv.guest_name ?? '';

  const meta = document.getElementById('welcome-meta');
  meta.replaceChildren();
  const addBadge = label => {
    const badge = document.createElement('span');
    badge.className = 'badge';
    badge.textContent = label;
    meta.appendChild(badge);
  };
  if (inv.table_label) addBadge('🪑 Table ' + inv.table_label);
  if (inv.chair_number) addBadge('💺 Chaise ' + inv.chair_number);

  updateSteps(inv.is_unlocked ? 3 : 1);

  document.getElementById('welcome-locked').style.display   = inv.is_unlocked ? 'none'  : 'block';
  document.getElementById('welcome-unlocked').style.display = inv.is_unlocked ? 'block' : 'none';
}

function updateSteps(current) {
  for (let i = 1; i <= 3; i++) {
    const el = document.getElementById('step' + i);
    if (!el) continue;
    el.className = 'step' + (i < current ? ' done' : i === current ? ' active' : '');
  }
  for (let i = 1; i <= 2; i++) {
    const ln = document.getElementById('line' + i);
    if (ln) ln.className = 'step-line' + (i < current ? ' done' : '');
  }
}

// ═══════════════════════════════════════════════════════
// RECORD SCREEN
// ═══════════════════════════════════════════════════════
function selectMediaType(type) {
  State.mediaType = type;
  document.getElementById('tab-audio').classList.toggle('selected', type === 'audio');
  document.getElementById('tab-video').classList.toggle('selected', type === 'video');
  resetRecorder();
}

async function startStream() {
  try {
    const constraints = State.mediaType === 'video'
      ? { video: { facingMode: 'user' }, audio: true }
      : { audio: true };
    State.stream = await navigator.mediaDevices.getUserMedia(constraints);

    const vid = document.getElementById('preview-video');
    const aud = document.getElementById('preview-audio-wrap');

    if (State.mediaType === 'video') {
      vid.srcObject = State.stream;
      vid.style.display = 'block';
      aud.style.display = 'none';
    } else {
      vid.style.display = 'none';
      aud.style.display = 'flex';
    }
    return true;
  } catch (e) {
    showAlert('rec', 'Accès au micro/caméra refusé. Vérifiez les permissions de votre navigateur.');
    return false;
  }
}

function stopStream() {
  if (State.stream) {
    State.stream.getTracks().forEach(t => t.stop());
    State.stream = null;
  }
}

async function toggleRecord() {
  if (State.isRecording) {
    stopRecording();
  } else {
    await startRecording();
  }
}

async function startRecording() {
  clearAlert('rec');
  const ok = await startStream();
  if (!ok) return;

  State.chunks   = [];
  State.blob     = null;
  State.duration = 0;

  const mimeType = State.mediaType === 'video'
    ? (MediaRecorder.isTypeSupported('video/webm;codecs=vp9') ? 'video/webm;codecs=vp9' : 'video/webm')
    : (MediaRecorder.isTypeSupported('audio/webm;codecs=opus') ? 'audio/webm;codecs=opus' : 'audio/webm');

  State.recorder = new MediaRecorder(State.stream, { mimeType });
  State.recorder.ondataavailable = e => { if (e.data.size > 0) State.chunks.push(e.data); };
  State.recorder.onstop = onRecordStop;
  State.recorder.start(500);

  State.isRecording = true;
  State.timerStart  = Date.now();
  document.getElementById('btn-record').classList.add('recording');
  document.getElementById('btn-record-icon').innerHTML = STOP_ICON_HTML;
  vibrate(15); // short haptic on record start
  document.getElementById('rec-hint').textContent = 'En cours… appuyez pour arrêter';
  document.getElementById('playback-area').style.display = 'none';
  document.getElementById('btn-submit').disabled = true;

  startTimer();
}

function stopRecording() {
  vibrate(10); // short haptic on stop
  if (State.recorder && State.recorder.state !== 'inactive') {
    State.recorder.stop();
  }
  stopStream();
  stopTimer();
  State.isRecording = false;
  document.getElementById('btn-record').classList.remove('recording');
  document.getElementById('btn-record-icon').innerHTML = RECORD_ICON_HTML;
  document.getElementById('rec-hint').textContent = 'Appuyez pour ré-enregistrer';
}

function onRecordStop() {
  State.blob = new Blob(State.chunks, {
    type: State.mediaType === 'video' ? 'video/webm' : 'audio/webm'
  });
  State.duration = (Date.now() - State.timerStart) / 1000;

  const url = URL.createObjectURL(State.blob);
  const playArea = document.getElementById('playback-area');
  playArea.style.display = 'flex';

  const pbVideo = document.getElementById('playback-video');
  const pbAudio = document.getElementById('playback-audio');

  if (State.mediaType === 'video') {
    pbVideo.src = url; pbVideo.style.display = 'block';
    pbAudio.style.display = 'none';
  } else {
    pbAudio.src = url; pbAudio.style.display = 'block';
    pbVideo.style.display = 'none';
  }

  // Hide live previews
  document.getElementById('preview-video').style.display = 'none';
  document.getElementById('preview-audio-wrap').style.display = 'none';

  const durSec = Math.floor(State.duration);
  const label  = durSec >= 60
    ? (Math.floor(durSec/60) + 'min ' + (durSec%60) + 's')
    : (durSec + ' secondes');

  const ok = State.duration >= 30;
  const durOk = document.getElementById('duration-ok');
  const durKo = document.getElementById('duration-ko');
  durOk.style.display = ok ? 'flex' : 'none';
  durKo.style.display = ok ? 'none' : 'flex';
  if (ok) document.getElementById('final-duration').textContent = label;

  document.getElementById('btn-submit').disabled = !ok;
}

// ── Haptic feedback ──
function vibrate(pattern) {
  if ('vibrate' in navigator) {
    try { navigator.vibrate(pattern); } catch (_) {}
  }
}

// ── Timer (requestAnimationFrame for 60fps smoothness) ──
function startTimer() {
  const circle = document.getElementById('timer-circle');
  const circumference = 264;
  const timerWrap = document.querySelector('.timer-wrap');
  if (timerWrap) timerWrap.classList.add('recording');
  let lastDisplayed = -1;
  let vibrateAt30 = false;

  function tick() {
    if (!State.isRecording) return;
    const elapsed = (Date.now() - State.timerStart) / 1000;
    const progress = Math.min(elapsed / 30, 1);

    // Smooth stroke update at 60fps
    circle.style.strokeDashoffset = String(circumference * (1 - progress));

    // Update text only when second changes (avoid layout thrash)
    const sec = Math.floor(elapsed);
    if (sec !== lastDisplayed) {
      lastDisplayed = sec;
      document.getElementById('timer-text').textContent = sec + 's';
      document.getElementById('timer-label').textContent =
        elapsed >= 30 ? 'Durée validée !' : 'Encore ' + Math.ceil(30 - elapsed) + 's…';

      // Vibrate at 30s threshold (success pattern: two short buzzes)
      if (elapsed >= 30 && !vibrateAt30) {
        vibrateAt30 = true;
        circle.classList.add('done');
        vibrate([50, 30, 50]);
      }
    }

    State.timerHandle = requestAnimationFrame(tick);
  }

  State.timerHandle = requestAnimationFrame(tick);
}
function stopTimer() {
  if (State.timerHandle) cancelAnimationFrame(State.timerHandle);
  const timerWrap = document.querySelector('.timer-wrap');
  if (timerWrap) timerWrap.classList.remove('recording');
}

function resetRecorder() {
  stopRecording();
  stopTimer();
  State.blob = null; State.chunks = []; State.duration = 0;
  document.getElementById('playback-area').style.display = 'none';
  document.getElementById('preview-video').style.display = 'none';
  document.getElementById('preview-audio-wrap').style.display =
    State.mediaType === 'audio' ? 'flex' : 'none';
  const circle = document.getElementById('timer-circle');
  circle.style.strokeDashoffset = '264';
  circle.classList.remove('done');
  circle.classList.remove('glow');
  document.getElementById('timer-text').textContent = '0s';
  document.getElementById('timer-label').textContent = 'Appuyez pour commencer';
  document.getElementById('btn-record-icon').innerHTML = RECORD_ICON_HTML;
  document.getElementById('rec-hint').textContent = "Appuyez pour démarrer l'enregistrement";
  document.getElementById('btn-submit').disabled = true;
  clearAlert('rec');
}

// ═══════════════════════════════════════════════════════
// SUBMIT MEDIA
// ═══════════════════════════════════════════════════════
async function submitMedia() {
  if (!State.blob || State.duration < 30) return;

  document.getElementById('btn-submit').disabled = true;
  showUpload('Obtention de l\\'URL d\\'upload…', 10);

  try {
    const ext      = State.mediaType === 'video' ? 'webm' : 'webm';
    const mimeType = State.blob.type;
    const fileName = State.mediaType + '_' + Date.now() + '.' + ext;

    // 1. Obtenir une signed upload URL
    const { signed_url, storage_path } = await apiFetch('/api/upload-url', {
      method: 'POST',
      body: JSON.stringify({
        token: State.token,
        media_type: State.mediaType,
        file_name: fileName,
        mime_type: mimeType,
      }),
    });

    showUpload('Upload du fichier…', 40);

    // 2. Upload direct vers Supabase Storage
    const uploadRes = await fetch(signed_url, {
      method: 'PUT',
      headers: { 'Content-Type': mimeType, 'x-upsert': 'true' },
      body: State.blob,
    });
    if (!uploadRes.ok) throw new Error('Échec de l\\'upload : ' + uploadRes.status);

    showUpload('Validation du message…', 80);

    // 3. Soumettre via RPC
    const result = await apiFetch('/api/submit', {
      method: 'POST',
      body: JSON.stringify({
        token: State.token,
        media_type: State.mediaType,
        storage_path,
        duration: Math.floor(State.duration),
        mime_type: mimeType,
      }),
    });

    showUpload('Message envoyé !', 100);
    vibrate([30, 50, 30]); // success pattern
    State.invitation = result;

    setTimeout(() => {
      hideUpload();
      App.goToCard();
    }, 800);

  } catch (e) {
    hideUpload();
    showAlert('rec', e.message);
    document.getElementById('btn-submit').disabled = false;
  }
}

// ═══════════════════════════════════════════════════════
// CARD SCREEN
// ═══════════════════════════════════════════════════════
async function renderCard() {
  try {
    const data = await apiFetch('/api/card-url?token=' + encodeURIComponent(State.token));
    State.invitation  = data;
    State.signedPngUrl = data.signed_png_url;
    State.signedPdfUrl = data.signed_pdf_url;

    const ev = data.event ?? {};
    document.getElementById('card-couple').textContent =
      (ev.bride_name ?? '') + ' & ' + (ev.groom_name ?? '');
    document.getElementById('card-name').textContent     = data.guest_name ?? '';
    document.getElementById('card-table').textContent    = data.table_label  ? '🪑 Table '  + data.table_label  : '';
    document.getElementById('card-chair').textContent    = data.chair_number ? '💺 Chaise ' + data.chair_number : '';
    document.getElementById('card-date').textContent     = ev.event_date_label ? '📅 ' + ev.event_date_label   : '';
    document.getElementById('card-location').textContent = ev.location         ? '📍 ' + ev.location           : '';
    document.getElementById('card-code').textContent     = data.invitation_code ? '#' + data.invitation_code   : '';

    const dlRow = document.getElementById('download-row');
    if (data.signed_png_url || data.signed_pdf_url) {
      dlRow.style.display = 'flex';
      document.getElementById('btn-dl-png').style.display = data.signed_png_url ? 'block' : 'none';
      document.getElementById('btn-dl-pdf').style.display = data.signed_pdf_url ? 'block' : 'none';
    }
  } catch (e) {
    console.error('Erreur chargement carte', e);
  }
}

function downloadCard(type) {
  const url = type === 'png' ? State.signedPngUrl : State.signedPdfUrl;
  if (!url) return;
  const a = document.createElement('a');
  a.href = url;
  a.download = 'invitation_' + (State.invitation?.guest_name ?? 'mariage') + '.' + type;
  a.click();
}

function shareCard() {
  const shareUrl = location.href.split('?')[0] + '?token=' + State.token;
  if (navigator.share) {
    navigator.share({
      title: 'Mon invitation de mariage',
      text: 'Voici mon invitation pour le mariage !',
      url: shareUrl,
    }).catch(() => {});
  } else {
    navigator.clipboard.writeText(shareUrl).then(() => {
      alert('Lien copié dans le presse-papier !');
    });
  }
}

// ═══════════════════════════════════════════════════════
// UPLOAD PROGRESS
// ═══════════════════════════════════════════════════════
function showUpload(label, pct) {
  document.getElementById('upload-status').classList.add('visible');
  document.getElementById('upload-bar').style.width = pct + '%';
  document.getElementById('upload-label').textContent = label;
}
function hideUpload() {
  document.getElementById('upload-status').classList.remove('visible');
}

// ═══════════════════════════════════════════════════════
// ALERTS
// ═══════════════════════════════════════════════════════
function showAlert(id, msg) {
  const el = document.getElementById('alert-' + id);
  if (el) { el.textContent = msg; el.classList.add('visible'); }
}
function clearAlert(id) {
  const el = document.getElementById('alert-' + id);
  if (el) { el.textContent = ''; el.classList.remove('visible'); }
}

// ═══════════════════════════════════════════════════════
// PUBLIC APP INTERFACE
// ═══════════════════════════════════════════════════════
const App = {
  goToWelcome() {
    resetRecorder();
    renderWelcome();
    updateSteps(State.invitation?.is_unlocked ? 3 : 1);
    showScreen('welcome');
  },
  goToRecord() {
    updateSteps(2);
    showScreen('record');
    selectMediaType('audio');
  },
  async goToCard() {
    updateSteps(3);
    showScreen('card');
    await renderCard();
  },
  selectMediaType,
  toggleRecord,
  submitMedia,
  submitCheckIn,
  useAnotherInvitation,
  downloadCard,
  shareCard,
};

// ═══════════════════════════════════════════════════════
// BOOT
// ═══════════════════════════════════════════════════════
init();

// ── Register Service Worker ──
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js', { scope: './' }).then(reg => {
    console.log('SW registered:', reg.scope);
  }).catch(err => {
    console.warn('SW registration failed:', err);
  });
}
</script>
</body>
</html>`;
}

// ── Service Worker (PWA cache) ──────────────────────────────────────────────

function renderServiceWorker(): string {
  const CACHE_NAME = 'wedding-portal-v1';
  const PRECACHE_URLS = ['./', './manifest.json', './icon-192.png', './icon-512.png'];

  return /* js */`
// Wedding Portal Service Worker
const CACHE_NAME = '${CACHE_NAME}';
const PRECACHE = ${JSON.stringify(PRECACHE_URLS)};

// Install: pre-cache shell
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE))
      .then(() => self.skipWaiting())
  );
});

// Activate: cleanup old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

// Fetch: network-first for API, cache-first for static assets
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // API calls → network only (never cache tokens/signed URLs)
  if (url.pathname.includes('/api/')) return;

  // Static assets → cache-first, then network
  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        // Only cache successful same-origin responses
        if (response.ok && url.origin === self.location.origin) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        }
        return response;
      }).catch(() => {
        // Offline fallback: return cached index for navigation
        if (event.request.mode === 'navigate') {
          return caches.match('./');
        }
        return new Response('Offline', { status: 503 });
      });
    })
  );
});
`;
}

// ── SVG icon generator ──────────────────────────────────────────────────────

function renderIconSVG(size: number): string {
  const s = size;
  const r = s * 0.18;
  const ringR = s * 0.14;
  const ringW = s * 0.032;
  const cy = s * 0.42;
  const lx = s * 0.37;
  const rx = s * 0.63;
  const dSize = s * 0.028;
  const fontSize = Math.round(s * 0.075);
  return /* html */ `<svg xmlns="http://www.w3.org/2000/svg" width="${s}" height="${s}" viewBox="0 0 ${s} ${s}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#1a1a2e"/>
      <stop offset="50%" stop-color="#16213e"/>
      <stop offset="100%" stop-color="#0f3460"/>
    </linearGradient>
    <linearGradient id="gold" x1="${s * 0.25}" y1="${s * 0.25}" x2="${s * 0.75}" y2="${s * 0.65}" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#e8d49e"/>
      <stop offset="30%" stop-color="#c9a84c"/>
      <stop offset="70%" stop-color="#a07830"/>
      <stop offset="100%" stop-color="#c9a84c"/>
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="42%" r="28%">
      <stop offset="0%" stop-color="rgba(201,168,76,0.12)"/>
      <stop offset="100%" stop-color="rgba(201,168,76,0)"/>
    </radialGradient>
    <linearGradient id="hi" x1="${s * 0.3}" y1="${s * 0.2}" x2="${s * 0.5}" y2="${s * 0.5}" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="rgba(255,255,255,0.35)"/>
      <stop offset="100%" stop-color="rgba(255,255,255,0)"/>
    </linearGradient>
  </defs>
  <rect width="${s}" height="${s}" rx="${r}" fill="url(#bg)"/>
  <rect width="${s}" height="${s}" rx="${r}" fill="url(#glow)"/>
  <circle cx="${lx}" cy="${cy}" r="${ringR}" fill="none" stroke="url(#gold)" stroke-width="${ringW}"/>
  <circle cx="${rx}" cy="${cy}" r="${ringR}" fill="none" stroke="url(#gold)" stroke-width="${ringW}"/>
  <circle cx="${lx}" cy="${cy}" r="${ringR - ringW * 0.3}" fill="none" stroke="url(#hi)" stroke-width="${ringW * 0.5}" stroke-dasharray="${ringR * 1.2} ${ringR * 3}" stroke-dashoffset="-${ringR * 0.4}"/>
  <circle cx="${rx}" cy="${cy}" r="${ringR - ringW * 0.3}" fill="none" stroke="url(#hi)" stroke-width="${ringW * 0.5}" stroke-dasharray="${ringR * 1.2} ${ringR * 3}" stroke-dashoffset="-${ringR * 0.5}"/>
  <rect x="${s * 0.5 - dSize}" y="${cy - dSize}" width="${dSize * 2}" height="${dSize * 2}" rx="${dSize * 0.3}" fill="#c9a84c" transform="rotate(45 ${s * 0.5} ${cy})"/>
  <line x1="${s * 0.26}" y1="${s * 0.27}" x2="${s * 0.26}" y2="${s * 0.29}" stroke="#e8d49e" stroke-width="${s * 0.004}" stroke-linecap="round" opacity="0.7"/>
  <line x1="${s * 0.25}" y1="${s * 0.28}" x2="${s * 0.27}" y2="${s * 0.28}" stroke="#e8d49e" stroke-width="${s * 0.004}" stroke-linecap="round" opacity="0.7"/>
  <line x1="${s * 0.74}" y1="${s * 0.31}" x2="${s * 0.74}" y2="${s * 0.33}" stroke="#e8d49e" stroke-width="${s * 0.003}" stroke-linecap="round" opacity="0.5"/>
  <line x1="${s * 0.73}" y1="${s * 0.32}" x2="${s * 0.75}" y2="${s * 0.32}" stroke="#e8d49e" stroke-width="${s * 0.003}" stroke-linecap="round" opacity="0.5"/>
  <text x="${s * 0.5}" y="${s * 0.78}" text-anchor="middle" fill="#c9a84c" font-family="Georgia, serif" font-size="${fontSize}" font-weight="bold" letter-spacing="${fontSize * 0.3}">MARIAGE</text>
  <line x1="${s * 0.4}" y1="${s * 0.85}" x2="${s * 0.6}" y2="${s * 0.85}" stroke="rgba(201,168,76,0.3)" stroke-width="${s * 0.005}" stroke-linecap="round"/>
</svg>`;
}

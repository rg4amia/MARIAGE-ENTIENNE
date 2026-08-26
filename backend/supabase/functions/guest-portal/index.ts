import { createClient } from 'jsr:@supabase/supabase-js@2';
import { detectMediaDuration } from '../_shared/media-duration.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

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

  // ── SPA HTML ─────────────────────────────────────────────────────────────────
  // Toute autre route → on sert la SPA
  const token = url.searchParams.get('token') ?? '';
  return new Response(renderSPA(token, supabaseUrl), {
    headers: { 'Content-Type': 'text/html; charset=utf-8' },
  });
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

// ── SPA HTML/CSS/JS inline ───────────────────────────────────────────────────

function renderSPA(initialToken: string, supabaseUrl: string): string {
  return /* html */`<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0" />
  <title>Mon Invitation de Mariage</title>
  <style>
    /* ── Reset & base ── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --gold:   #c9a84c;
      --gold2:  #e8d49e;
      --dark:   #1a1a2e;
      --card:   #ffffff;
      --text:   #2d2d2d;
      --muted:  #7a7a8c;
      --danger: #e74c3c;
      --success:#27ae60;
      --radius: 20px;
      --shadow: 0 8px 32px rgba(0,0,0,0.12);
    }

    html, body {
      min-height: 100%;
      font-family: 'Georgia', serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      color: var(--text);
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
      font-size: 22px;
      color: var(--gold);
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
      background: linear-gradient(135deg, var(--gold), var(--gold2));
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
      background: #eee; color: var(--muted);
      transition: all .3s;
    }
    .step.done  { background: var(--success); color: #fff; }
    .step.active{ background: var(--gold);    color: #fff; }
    .step-line  { flex: 1; height: 2px; background: #eee; margin-top: 15px; max-width: 40px; }
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
    .media-tab {
      flex: 1;
      padding: 12px;
      border: 2px solid #e0e0e0;
      border-radius: 12px;
      background: #fafafa;
      cursor: pointer;
      text-align: center;
      font-size: 14px;
      transition: all .2s;
    }
    .media-tab:hover { border-color: var(--gold); }
    .media-tab.selected { border-color: var(--gold); background: #fffbf0; }
    .media-tab .icon { font-size: 28px; margin-bottom: 4px; }
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
    .timer-ring .bg   { stroke: #e0e0e0; }
    .timer-ring .prog { stroke: var(--gold); stroke-linecap: round; transition: stroke-dashoffset .5s; }
    .timer-ring .prog.done { stroke: var(--success); }
    .timer-text {
      position: absolute; inset: 0;
      display: flex; align-items: center; justify-content: center;
      font-size: 22px; font-weight: bold; color: var(--dark);
    }
    .timer-label { font-size: 12px; color: var(--muted); }

    /* Record button */
    .btn-record {
      width: 72px; height: 72px; border-radius: 50%;
      border: 4px solid var(--gold);
      background: #fff;
      cursor: pointer;
      display: flex; align-items: center; justify-content: center;
      font-size: 28px;
      transition: all .2s;
      box-shadow: 0 4px 12px rgba(0,0,0,.1);
    }
    .btn-record:hover { transform: scale(1.05); }
    .btn-record.recording { background: var(--danger); border-color: var(--danger); animation: pulse 1.2s infinite; }
    @keyframes pulse { 0%,100%{box-shadow:0 0 0 0 rgba(231,76,60,.4);} 50%{box-shadow:0 0 0 12px rgba(231,76,60,0);} }

    .rec-hint { font-size: 12px; color: var(--muted); text-align: center; }

    /* ── Progress bar ── */
    .progress-wrap { background: #eee; border-radius: 50px; height: 6px; overflow: hidden; }
    .progress-bar  { height: 100%; background: linear-gradient(90deg, var(--gold), var(--gold2)); border-radius: 50px; transition: width .3s; }

    /* ── Buttons ── */
    .btn {
      width: 100%; padding: 14px;
      border: none; border-radius: 12px;
      font-size: 15px; font-weight: 600; cursor: pointer;
      transition: all .2s; letter-spacing: .3px;
    }
    .btn-primary { background: linear-gradient(135deg, var(--gold), #a07830); color: #fff; }
    .btn-primary:hover { opacity: .9; transform: translateY(-1px); }
    .btn-primary:disabled { opacity: .5; cursor: not-allowed; transform: none; }
    .btn-outline { background: #fff; border: 2px solid var(--gold); color: var(--gold); }
    .btn-outline:hover { background: #fffbf0; }

    /* ── Card invitation ── */
    .invitation-card {
      background: linear-gradient(135deg, #1a1a2e, #0f3460);
      border-radius: 16px; padding: 32px 24px;
      text-align: center; color: #fff;
      border: 1px solid rgba(201,168,76,.3);
    }
    .invitation-card .couple { font-size: 22px; color: var(--gold); margin: 8px 0 16px; letter-spacing: 1px; }
    .invitation-card .divider { border: none; border-top: 1px solid rgba(201,168,76,.3); margin: 12px 0; }
    .invitation-card .inv-name { font-size: 28px; font-weight: bold; margin: 8px 0; }
    .invitation-card .inv-detail { font-size: 14px; color: rgba(255,255,255,.7); margin: 4px 0; }
    .invitation-card .inv-code {
      font-size: 12px; letter-spacing: 3px;
      color: rgba(255,255,255,.4); margin-top: 16px;
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
      display: none;
    }
    .alert.error   { background: #fdf0f0; color: var(--danger); border: 1px solid #f5c6c6; }
    .alert.success { background: #f0fdf4; color: var(--success); border: 1px solid #c6e9d0; }
    .alert.visible { display: block; }

    /* ── Loader ── */
    .loader {
      display: none; flex-direction: column; align-items: center; gap: 12px; padding: 32px;
    }
    .loader.visible { display: flex; }
    .spinner {
      width: 40px; height: 40px; border-radius: 50%;
      border: 4px solid #eee; border-top-color: var(--gold);
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
      <h2 style="color:#fff;margin-bottom:8px;">Invitation introuvable</h2>
      <p style="color:rgba(255,255,255,.6);font-size:14px;" id="error-msg">
        Ce lien d'invitation n'est pas valide ou a expiré.
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
          <div class="icon">🎵</div>
          <div class="label">Audio</div>
          <div class="desc">Message vocal</div>
        </div>
        <div class="media-tab" id="tab-video" onclick="App.selectMediaType('video')">
          <div class="icon">🎬</div>
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
            <div style="font-size:48px;" id="audio-idle-icon">🎤</div>
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
          <span id="btn-record-icon">⏺</span>
        </button>
        <div class="rec-hint" id="rec-hint">Appuyez pour démarrer l'enregistrement</div>

        <!-- Playback area (after recording) -->
        <div id="playback-area" style="display:none;width:100%;flex-direction:column;gap:12px;">
          <video id="playback-video" controls style="width:100%;border-radius:12px;display:none;"></video>
          <audio id="playback-audio" controls style="width:100%;display:none;"></audio>
          <div class="alert success visible" id="duration-ok" style="display:none;">
            ✅ Durée validée ! Votre message dure <strong id="final-duration"></strong>.
          </div>
          <div class="alert error visible" id="duration-ko" style="display:none;">
            ⚠️ Message trop court. Minimum 30 secondes requis.
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
      <button class="btn btn-outline" style="flex:1;" onclick="App.goToWelcome()">← Retour</button>
      <button class="btn btn-primary" style="flex:2;" id="btn-submit" onclick="App.submitMedia()" disabled>
        Envoyer mon message →
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

    <button class="btn btn-outline" onclick="App.goToWelcome()">← Retour à l'accueil</button>
  </div>

</div><!-- #app -->

<script>
// ═══════════════════════════════════════════════════════
// CONFIG — injectée côté serveur
// ═══════════════════════════════════════════════════════
const FUNCTION_BASE = '${supabaseUrl}/functions/v1/guest-portal';

// ═══════════════════════════════════════════════════════
// APP STATE
// ═══════════════════════════════════════════════════════
const State = {
  token:       ${JSON.stringify(initialToken)},
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
    renderWelcome();
    showScreen('welcome');
  } catch (e) {
    document.getElementById('error-msg').textContent = e.message;
    showScreen('error');
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
  document.getElementById('btn-record-icon').textContent = '⏹';
  document.getElementById('rec-hint').textContent = 'En cours… appuyez pour arrêter';
  document.getElementById('playback-area').style.display = 'none';
  document.getElementById('btn-submit').disabled = true;

  startTimer();
}

function stopRecording() {
  if (State.recorder && State.recorder.state !== 'inactive') {
    State.recorder.stop();
  }
  stopStream();
  stopTimer();
  State.isRecording = false;
  document.getElementById('btn-record').classList.remove('recording');
  document.getElementById('btn-record-icon').textContent = '⏺';
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
  durOk.style.display = ok ? 'block' : 'none';
  durKo.style.display = ok ? 'none'  : 'block';
  if (ok) document.getElementById('final-duration').textContent = label;

  document.getElementById('btn-submit').disabled = !ok;
}

// ── Timer ──
function startTimer() {
  const circle = document.getElementById('timer-circle');
  const circumference = 264;
  State.timerHandle = setInterval(() => {
    const elapsed = (Date.now() - State.timerStart) / 1000;
    const progress = Math.min(elapsed / 30, 1);
    circle.style.strokeDashoffset = circumference * (1 - progress);
    if (progress >= 1) circle.classList.add('done');
    document.getElementById('timer-text').textContent = Math.floor(elapsed) + 's';
    document.getElementById('timer-label').textContent =
      elapsed >= 30 ? '✅ Durée validée !' : 'Encore ' + Math.ceil(30 - elapsed) + 's…';
  }, 200);
}
function stopTimer() {
  clearInterval(State.timerHandle);
}

function resetRecorder() {
  stopRecording();
  stopTimer();
  State.blob = null; State.chunks = []; State.duration = 0;
  document.getElementById('playback-area').style.display = 'none';
  document.getElementById('preview-video').style.display = 'none';
  document.getElementById('preview-audio-wrap').style.display =
    State.mediaType === 'audio' ? 'flex' : 'none';
  document.getElementById('timer-circle').style.strokeDashoffset = '264';
  document.getElementById('timer-circle').classList.remove('done');
  document.getElementById('timer-text').textContent = '0s';
  document.getElementById('timer-label').textContent = 'Appuyez pour commencer';
  document.getElementById('btn-record-icon').textContent = '⏺';
  document.getElementById('rec-hint').textContent = 'Appuyez pour démarrer l\\'enregistrement';
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
  downloadCard,
  shareCard,
};

// ═══════════════════════════════════════════════════════
// BOOT
// ═══════════════════════════════════════════════════════
init();
</script>
</body>
</html>`;
}

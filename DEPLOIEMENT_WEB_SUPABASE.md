# Déploiement mobile, portail invité et Supabase

## Architecture retenue

- `weeding_app` est le back-office Flutter des mariés (mobile et Web admin).
- `guest-portal-web` est l'unique interface publique des invités, publiée sur GitHub Pages.
- Supabase fournit Auth, PostgreSQL, Storage et les Edge Functions.
- Un invité ne crée pas de compte : son token QR opaque autorise uniquement son parcours.

Le portail public est servi depuis :

```text
https://rg4amia.github.io/MARIAGE-ENTIENNE/?token=TOKEN
```

La passerelle `*.supabase.co` transforme volontairement les réponses HTML des Edge
Functions en `text/plain`. La page GitHub Pages charge donc le shell via
`guest-portal/api/shell`, puis utilise les routes API Supabase pour les données et
les médias.

Les codes QR courts passent par `invite/{shortCode}`. Cette fonction compte le
scan de manière atomique puis redirige vers `guest-portal`.

## QR commun à l’entrée de la salle

L’administrateur ouvre **Plus → QR d’entrée de la salle** ou l’action rapide du
tableau de bord. L’application génère un QR commun à afficher à l’entrée.

Après le scan :

1. le portail reconnaît l’événement ;
2. il réutilise automatiquement l’invitation mémorisée sur le téléphone ;
3. sinon, l’invité saisit le code `INV-...` visible sur sa carte ;
4. la carte doit déjà être débloquée ;
5. l’arrivée est enregistrée une seule fois dans `guest_check_ins` ;
6. le nom, la table et la chaise sont confirmés à l’écran.

Le renouvellement du QR invalide seulement l’ancien code d’entrée. Les arrivées
déjà enregistrées sont conservées. Les compteurs de scans et d’entrées sont
actualisés dans Flutter avec Supabase Realtime.

## Ordre de déploiement

Depuis la racine du dépôt :

```bash
supabase config push --workdir backend
supabase db push --workdir backend
supabase functions deploy guest-portal --workdir backend --no-verify-jwt
supabase functions deploy invite --workdir backend --no-verify-jwt
supabase functions deploy invite-analytics --workdir backend
supabase functions deploy validate-media --workdir backend
```

Le workflow `.github/workflows/deploy-guest-portal.yml` publie automatiquement
`backend/guest-portal-web` sur GitHub Pages après un push sur `main`. Dans les
paramètres GitHub du dépôt, la source Pages doit être réglée sur **GitHub Actions**.

Les inscriptions publiques sont désactivées. Le premier administrateur doit
être créé depuis Supabase Dashboard avec les métadonnées utilisateur suivantes :

```json
{
  "full_name": "Administrateur Mariage",
  "event_id": "00000000-0000-0000-0000-000000000001"
}
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` et `SUPABASE_SERVICE_ROLE_KEY` sont fournis
par Supabase aux fonctions. Pour remplacer l'URL GitHub Pages par un domaine
personnalisé, configurer également :

```bash
supabase secrets set GUEST_PORTAL_URL=https://votre-portail.example --workdir backend
```

Ne jamais placer la clé `service_role` dans Flutter ou dans le JavaScript livré
au navigateur.

## Validation média

1. Le navigateur demande une URL d'upload signée.
2. Le fichier est envoyé dans le bucket privé `guest-media`.
3. Le serveur télécharge le fichier et lit sa durée MP4/M4A, WebM ou WAV.
4. La durée serveur doit être d'au moins 30 secondes et correspondre à la durée
   annoncée par le navigateur avec une tolérance de 5 secondes.
5. La carte est alors déverrouillée et ses éventuels fichiers PNG/PDF sont servis
   avec des URL signées temporaires.

## Vérifications avant publication

```bash
cd weeding_app
flutter analyze
flutter test
flutter build web

cd ../backend
deno test supabase/functions/_shared/media-duration_test.ts
deno check --node-modules-dir=auto \
  supabase/functions/guest-portal/index.ts \
  supabase/functions/invite/index.ts \
  supabase/functions/invite-analytics/index.ts \
  supabase/functions/validate-media/index.ts

cd ..
supabase db push --dry-run --workdir backend
```

Le build Flutter Web admin est généré dans `weeding_app/build/web`. Le portail
invité doit être publié sur un hébergement statique externe à `supabase.co`.

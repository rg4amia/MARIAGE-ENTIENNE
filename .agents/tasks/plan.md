# Implementation Plan — Correction de 3 bugs (Mariage Kodjo & Marie Ange)

## Contexte technique

- **App mobile** : Flutter / GetX dans `weeding_app/lib/`
- **Backend** : Supabase Edge Functions dans `backend/supabase/functions/`, migrations SQL dans `backend/supabase/migrations/`
- **Portail invités** : SPA HTML inline dans `backend/supabase/functions/guest-portal/index.ts` + page statique `backend/guest-portal-web/index.html`
- **Seed de base** : `backend/supabase/seed.sql` (données de démarrage du seul événement)
- **Commande de vérification mobile** : `flutter test` dans `weeding_app/`
- **Commande de build mobile** : `flutter build apk --debug` dans `weeding_app/`

---

## Bug 1 — En-tête incorrect : "Mariage Entienne" au lieu de "Kodjo & Marie Ange"

### Cause racine identifiée

Les noms du couple sont stockés dans la table `wedding_events` (colonnes `title`, `bride_name`, `groom_name`).
Le fichier `backend/supabase/seed.sql` a initialisé l'événement avec :
```sql
title      = 'Mariage Entienne'
bride_name = 'Aimee'
groom_name = 'Entienne'
```
Ce seed n'affecte que le démarrage local (il est protégé par `ON CONFLICT (id) DO NOTHING` donc en production la ligne existe déjà avec les mêmes valeurs si elle a été exécutée).
Les noms corrects — `Mawule Kodjo` et `Tiemele Marie Ange` — doivent être mis en base via l'app mobile (Settings) **ou** une migration SQL de correction. Il n'y a aucun texte hardcodé dans le code Flutter (tout est lu dynamiquement via `WeddingSettingsRepository.getSettings()`).

### Ce qu'affiche l'app

- **Settings page** → `_buildWeddingInfoCard` lit `bride_name` / `groom_name` depuis la DB → affiche "Aimee & Entienne"
- **Message WhatsApp** → `whatsapp_helper.dart` ligne 111 : `'💍 *Wedding $groom ET $bride*'` → affiche "Wedding Entienne ET Aimee"
- **Email subject** → `whatsapp_helper.dart` ligne 65 : `'Invitation — $couple'`
- **Portail invités HTML** → le titre de la carte est généré par `renderSPA()` dans `guest-portal/index.ts`, il lit les données de l'invitation via `get_invitation_by_token` (données venant aussi de `wedding_events`)

### Fichiers à modifier

- [ ] **1a. Corriger les données en production via l'app Settings (solution recommandée)**
  - Ouvrir l'app, aller dans Paramètres → modifier les champs Mariée / Marié
  - Saisir : Mariée = `Tiemele Marie Ange`, Marié = `Mawule Kodjo`, Titre = `Mariage Kodjo et Marie Ange`
  - Cela appelle `WeddingSettingsRepository.updateSettings()` → `UPDATE wedding_events SET bride_name, groom_name, title WHERE id = current_event_id()`
  - **Aucun fichier code à modifier — correction de donnée pure**

- [ ] **1b. Corriger le seed local pour éviter la même erreur à la prochaine réinstallation**
  - Fichier : `backend/supabase/seed.sql`
  - Remplacer :
    ```sql
    'mariage-entienne',
    'Mariage Entienne',
    'Aimee',
    'Entienne',
    ```
  - Par :
    ```sql
    'mariage-kodjo-marie-ange',
    'Mariage Kodjo et Marie Ange',
    'Tiemele Marie Ange',
    'Mawule Kodjo',
    ```

- [ ] **1c. Migration SQL de rattrapage (à appliquer si la correction via l'app n'est pas accessible)**
  - Créer `backend/supabase/migrations/20260904000000_fix_couple_names.sql` :
    ```sql
    -- Corrige les noms du couple pour l'événement de production
    UPDATE public.wedding_events
    SET
      title      = 'Mariage Kodjo et Marie Ange',
      bride_name = 'Tiemele Marie Ange',
      groom_name = 'Mawule Kodjo',
      slug       = 'mariage-kodjo-marie-ange',
      updated_at = timezone('utc', now())
    WHERE id = '00000000-0000-0000-0000-000000000001';
    ```
  - Appliquer via Supabase Dashboard → SQL Editor, ou `supabase db push`

### Vérification

1. App Settings → la carte "Info mariage" doit afficher "Tiemele Marie Ange & Mawule Kodjo"
2. Envoyer une invitation WhatsApp → le message doit commencer par `💍 *Wedding Mawule Kodjo ET Tiemele Marie Ange*`
3. `flutter test weeding_app/test/` — tous les tests existants passent (aucun test ne vérifie les noms hardcodés)

---

## Bug 2 — QR Code non fonctionnel sur la carte d'invitation de l'invité

### Cause racine identifiée

Il y a **deux QR codes distincts** dans l'app ; chacun a son propre problème :

#### QR code sur la carte `InvitationCardWidget` (portail invité — écran "Carte débloquée")

Fichier : `weeding_app/lib/app/modules/guest_access/guest_access_page.dart`, méthode `_buildCardUnlocked()`

Ligne incriminée :
```dart
child: InvitationCardWidget(
  ...
  qrToken: g?.qrToken,   // ← encode le token brut (ex: "mary-a1b2c3d4e5f6")
  ...
)
```

Le `InvitationCardWidget` (dans `invitation_card_generator.dart` ligne 172) encode `qrToken` dans le QR :
```dart
QrImageView(data: qrToken!, ...)
```

**Problème** : le QR code encode uniquement le token brut de l'invité (ex : `mary-a1b2c3d4e5f6`), pas une URL complète. Le scanner à l'entrée qui tente de résoudre cette valeur ne peut rien en faire s'il attend une URL ou un code d'invitation complet.

**Solution** : encoder l'URL complète du portail (la même valeur que `invitation.webUrl` ou `invitation.qrPayload`). Le `GuestAccessController` charge déjà l'invitation (`_loadInvitation`) et expose `controller.invitation.value` avec son champ `qrPayload`.

Modifier `_buildCardUnlocked()` :
```dart
// Avant :
qrToken: g?.qrToken,

// Après :
qrToken: controller.invitation.value?.qrPayload ?? g?.qrToken,
```

Fichier à modifier : `weeding_app/lib/app/modules/guest_access/guest_access_page.dart`

#### QR code dans `GuestDetailPage` (vue admin)

Fichier : `weeding_app/lib/app/modules/guests/guest_detail_page.dart`, lignes ~490–500

```dart
child: _guestLink == null
    ? const Icon(Icons.lock_outline, size: 60)
    : QrImageView(data: _getInviteUrl()),
```

`_getInviteUrl()` construit l'URL ainsi :
```dart
String _getInviteUrl() {
  if (_guestLink == null) return '';
  final supabaseUrl = Supabase.instance.client.rest.url;
  final baseUrl = supabaseUrl.replaceAll(RegExp(r'/rest/v1.*'), '');
  return _guestLink!.getInviteUrl(baseUrl);
}
```

Et `GuestLink.getInviteUrl()` dans `guest_link.dart` :
```dart
String getInviteUrl(String supabaseUrl) {
  final host = Uri.parse(supabaseUrl).host;
  return 'https://$host/functions/v1/invite/$shortCode';
}
```

Ce chemin `/functions/v1/invite/$shortCode` correspond à la Edge Function `invite/index.ts`. L'URL est donc correcte et le QR encode bien une URL valide — **mais seulement si `_guestLink != null`**. Si le lien n'a pas encore été créé (l'invité n'a pas encore de `guest_link` en base), le QR affiche une icône cadenas.

**Solution** : le `_loadOrCreateLink()` déjà présent dans l'initState crée le lien s'il n'existe pas. Aucun bug de logique ici, c'est un problème de timing : `_guestLink` peut être null si l'assignation de place est récente et `createGuestLink` a échoué silencieusement (l'erreur est catchée dans `GuestLinkRepository.createGuestLink`). La vraie robustesse est de s'assurer que `assignSeatToGuest()` dans le controller crée bien le lien (ce qu'il fait déjà à la ligne `await _linkRepository.createGuestLink(guestId)`).

**Correction résiduelle** : afficher un message d'erreur clair si `_guestLink` est null après chargement, plutôt qu'une icône cadenas silencieuse :

```dart
// Dans guest_detail_page.dart, remplacer :
child: _guestLink == null
    ? const Icon(Icons.lock_outline, size: 60)
    : QrImageView(data: _getInviteUrl()),

// Par :
child: _guestLink == null
    ? const Text(
        'QR non disponible.\nAssignez d\'abord une place.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      )
    : QrImageView(data: _getInviteUrl()),
```

#### QR entrée (`EntranceQrPage`) — NON CONCERNÉ PAR CE BUG

La page `entrance_qr_page.dart` fonctionne via `EntranceRepository.getOrCreate()` → RPC `manage_entrance_qr` qui génère une URL valide. Ce QR est destiné aux organisateurs (affiché à l'entrée), pas aux invités. C'est un QR différent.

### Fichiers à modifier

| Fichier | Ligne | Changement |
|---|---|---|
| `weeding_app/lib/app/modules/guest_access/guest_access_page.dart` | `_buildCardUnlocked()` — argument `qrToken` | Remplacer `g?.qrToken` par `controller.invitation.value?.qrPayload ?? g?.qrToken` |
| `weeding_app/lib/app/modules/guests/guest_detail_page.dart` | Affichage QR dans `_isLoadingLink` else block | Remplacer l'icône cadenas par un texte explicatif |

### Aucune migration de base de données nécessaire

La colonne `qr_payload` est déjà présente dans `invitations` et contient l'URL complète. L'`invitation` est déjà chargée dans `GuestAccessController._loadInvitation()`.

### Vérification

1. Créer un invité test, lui assigner une place, ouvrir son portail et compléter l'enregistrement
2. Sur l'écran "Carte débloquée", scanner le QR avec un téléphone → il doit ouvrir l'URL du portail (`https://rg4amia.github.io/MARIAGE-ENTIENNE/?token=...`)
3. Dans l'app admin, vue détail d'un invité avec lien existant → le QR doit être scannable et pointer vers l'URL d'invitation
4. `flutter test weeding_app/test/` — tous les tests passent

---

## Bug 3 — Table et chaise affichées "Non assignée" malgré une assignation existante

### Cause racine identifiée

**Deux problèmes distincts**, l'un dans la vue admin (`guest_detail_page.dart`) et l'autre dans la carte d'invitation du portail.

#### Problème 3a : Vue admin — `GuestDetailPage` affiche "Non assignée"

La requête `getGuestSeat()` dans `guest_repository.dart` :
```dart
final response = await _client
    .from('chairs')
    .select(
      'id, guest_id, table_id, chair_number, created_at, seating_tables!chairs_table_id_fkey(label)',
    )
    .eq('guest_id', guestId)
    .maybeSingle();
```

Le `GuestSeat.fromJson` lit le label de la table ainsi :
```dart
tableLabel:
    (json['table_label'] ??
            (json['seating_tables'] as Map<String, dynamic>?)?['label'] ??
            '')
        as String,
```

La réponse Supabase PostgREST pour une jointure avec `!fkey` ressemble à :
```json
{
  "id": "...",
  "guest_id": "...",
  "table_id": "...",
  "chair_number": 6,
  "created_at": "...",
  "seating_tables": { "label": "Table 6" }
}
```

**Il n'y a pas de colonne `table_label` à la racine** — PostgREST retourne la jointure dans une clé `seating_tables` imbriquée. La logique de `fromJson` le gère correctement à condition que le cast `as Map<String, dynamic>?` fonctionne.

**Le problème réel** : la vue admin utilise `FutureBuilder` sans écoute réactive. Quand l'utilisateur assigne une place et revient sur `GuestDetailPage`, le `Future` est reconstruit mais la page n'est **pas rechargée** — elle affiche le résultat en cache de l'objet `Guest` passé en argument qui lui ne contient pas la seat. Il faut forcer le rechargement.

Mais surtout : la page arrive via `Get.arguments as Guest` — cet objet Guest est l'objet **avant** l'assignation de place (s'il vient d'une navigation sans rechargement). Après `assignSeatToGuest()`, le controller appelle `loadGuests()` mais la page de détail a déjà son `_guest` local figé.

**Solution** : la `FutureBuilder` appelle `controller.getGuestSeat(guest.id)` à chaque rebuild. La clé `guest` est locale et ne change pas. Il faut utiliser `guest.id` qui est stable — ce n'est pas le problème. Le vrai problème est que le `FutureBuilder` ne se rebuild pas automatiquement après une assignation (la page de détail reste ouverte).

**Correction** : dans `_showAssignDialog` → après une assignation réussie, forcer un `setState` pour rebuild le `FutureBuilder`. Le callback `onAssigned` existe déjà et appelle `_loadOrCreateLink`. Ajouter un `setState` à ce callback :

```dart
// Fichier : guest_detail_page.dart — classe _AssignSheet, callback onAssigned
// Actuellement le callback onAssigned appelle _loadOrCreateLink
// Remplacer la définition de onAssigned dans _showAssignDialog pour aussi refresher le guest

void _showAssignDialog(...) async {
  ...
  showModalBottomSheet(
    ...
    builder: (ctx) => _AssignSheet(
      tables: tables,
      controller: controller,
      guest: guest,
      onAssigned: () {
        _loadOrCreateLink();       // déjà là
        setState(() {});            // ← AJOUTER pour rebuild les FutureBuilder
      },
    ),
  );
}
```

#### Problème 3b : Carte d'invitation du portail invité — TABLE et PLACE affichent des UUID au lieu des labels

Fichier : `weeding_app/lib/app/modules/guest_access/guest_access_page.dart`, méthode `_buildCardUnlocked()` :

```dart
child: InvitationCardWidget(
  ...
  tableName: controller.guestSeat.value?.tableId ?? 'Non assigné',  // ← tableId = UUID !
  seatNumber: controller.guestSeat.value?.chairId ?? '-',             // ← chairId = UUID !
  ...
),
```

**Les champs `tableId` et `chairId` sont des UUID** (ex: `550e8400-e29b-41d4-a716-446655440000`), pas des labels lisibles. Les champs corrects sont `tableLabel` et `chairNumber`.

**Correction** :
```dart
// Avant :
tableName: controller.guestSeat.value?.tableId ?? 'Non assigné',
seatNumber: controller.guestSeat.value?.chairId ?? '-',

// Après :
tableName: controller.guestSeat.value?.tableLabel ?? 'Non assigné',
seatNumber: controller.guestSeat.value != null
    ? '${controller.guestSeat.value!.chairNumber}'
    : '-',
```

### Fichiers à modifier

| Fichier | Emplacement | Changement |
|---|---|---|
| `weeding_app/lib/app/modules/guest_access/guest_access_page.dart` | `_buildCardUnlocked()` — arguments `tableName` et `seatNumber` de `InvitationCardWidget` | Remplacer `tableId` → `tableLabel`, `chairId` → `'${chairNumber}'` |
| `weeding_app/lib/app/modules/guests/guest_detail_page.dart` | `_showAssignDialog()` — callback `onAssigned` | Ajouter `setState(() {})` pour forcer le rebuild du `FutureBuilder` de la seat |

### Aucune migration de base de données nécessaire

La colonne `chair_number` est bien présente dans `chairs`. La jointure `seating_tables!chairs_table_id_fkey(label)` dans `getGuestSeat()` retourne déjà le label. Le `GuestSeat.fromJson` map correctement ces données dans `tableLabel` et `chairNumber`. Le bug est purement côté affichage Flutter.

### Vérification

1. Dans l'app admin : ouvrir la fiche de Mary → doit afficher "Table: Table 6" et "Chaise: 6" (ou le numéro exact assigné)
2. Ouvrir le portail invité de Mary, compléter l'enregistrement → la carte doit afficher "TABLE / Table 6" et "PLACE / 6" (pas des UUID)
3. Assigner une nouvelle place depuis la fiche invité → après fermeture du dialog, la fiche doit immédiatement afficher la nouvelle table sans avoir à rouvrir la page
4. `flutter test weeding_app/test/` — tous les tests passent

---

## Récapitulatif des fichiers à modifier

| Fichier | Bug | Nature |
|---|---|---|
| `backend/supabase/seed.sql` | Bug 1 | Corriger `title`, `bride_name`, `groom_name` |
| `backend/supabase/migrations/20260904000000_fix_couple_names.sql` (à créer) | Bug 1 | Migration SQL pour corriger les données en production |
| `weeding_app/lib/app/modules/guest_access/guest_access_page.dart` | Bug 2 + Bug 3b | `qrToken` → `qr_payload`, `tableId` → `tableLabel`, `chairId` → `chairNumber` |
| `weeding_app/lib/app/modules/guests/guest_detail_page.dart` | Bug 2 + Bug 3a | Texte pour QR null, `setState` après assignation |

## Ordre d'exécution recommandé

1. Appliquer la migration SQL Bug 1 en production (Dashboard Supabase)
2. Corriger `guest_access_page.dart` (Bug 2 + Bug 3b en un seul bloc)
3. Corriger `guest_detail_page.dart` (Bug 2 + Bug 3a en un seul bloc)
4. Corriger `seed.sql` (évite la regression locale)
5. `flutter test` → vérifier que tout passe
6. Tester manuellement avec un compte invité test

## Aucune migration de schéma nécessaire

Tous les champs utilisés (`qr_payload`, `table_label` via jointure, `chair_number`) existent déjà en base. Les corrections sont exclusivement dans le code Flutter (2 fichiers) et les données initiales (seed + migration de données).

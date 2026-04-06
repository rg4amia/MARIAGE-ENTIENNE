# Application Mariage Entienne

## 1. Prompt Produit Reorganise

Concevoir une application mobile Flutter basee sur Supabase et GetX pour la gestion numerique des invitations de mariage.

### Objectif principal

L'application doit permettre aux maries de creer et gerer :
- des tables
- des chaises
- des invites
- des cartes d'invitation numeriques personnalisees

Chaque invite recoit une invitation associee a :
- son nom
- son numero de table
- son numero de chaise
- un QR code unique

### Regle metier principale

Avant de pouvoir acceder a sa carte d'invitation ou la telecharger, chaque invite doit obligatoirement enregistrer :
- soit une video d'au moins 30 secondes
- soit un audio d'au moins 30 secondes

### Parcours attendu

1. Les maries creent les tables et les chaises dans l'application.
2. Les maries attribuent une chaise et une table a un invite.
3. Cette attribution genere automatiquement une carte d'invitation numerique.
4. La carte genere aussi un QR code unique.
5. Les maries envoient ce QR code a l'invite.
6. L'invite scanne le QR code.
7. L'invite arrive sur un ecran securise de validation.
8. L'invite enregistre un audio ou une video de minimum 30 secondes.
9. Une fois la preuve deposee, l'invite peut visualiser et telecharger sa carte d'invitation virtuelle.

### Technologies imposees

- Flutter
- GetX
- Supabase

### Fonctionnalites minimales MVP

#### Espace maries
- Connexion securisee
- Creation, modification et suppression des tables
- Creation automatique ou manuelle des chaises par table
- Creation et gestion des invites
- Attribution d'un invite a une table et une chaise
- Generation de carte d'invitation
- Generation du QR code associe a l'invite
- Suivi des invites ayant deja depose leur audio/video

#### Espace invite
- Acces via QR code ou lien unique
- Verification de l'invitation
- Enregistrement audio ou video
- Controle de la duree minimale de 30 secondes
- Upload du media dans Supabase Storage
- Deblocage de la carte d'invitation
- Telechargement ou partage de la carte

#### Back-office metier
- Etat d'une invitation : en attente, media recu, carte debloquee
- Historique des envois
- Statut d'occupation des tables et chaises

## 2. Cadrage Fonctionnel

### Roles

#### 1. Marie / Administrateur
- gere l'organisation
- cree les tables
- cree les chaises
- ajoute les invites
- attribue les places
- genere les invitations
- consulte les medias envoyes

#### 2. Invite
- accede a son invitation via QR code ou lien
- enregistre une video ou un audio
- consulte et telecharge sa carte une fois la condition validee

### Regles metier detaillees

- Une chaise appartient a une seule table.
- Une chaise ne peut etre attribuee qu'a un seul invite.
- Un invite ne peut avoir qu'une seule invitation active.
- Une invitation n'est telechargeable que si un media valide a ete depose.
- Un media est valide si sa duree est superieure ou egale a 30 secondes.
- Le QR code doit pointer vers une page ou une route securisee contenant un token unique.

## 3. Proposition d'Architecture

### Cote Flutter

- `Flutter` pour l'application mobile
- `GetX` pour :
  - le routage
  - l'injection de dependances
  - la gestion d'etat
- `supabase_flutter` pour auth, base et storage
- package QR code pour generer et lire les QR codes
- package audio/video pour capture locale
- package PDF ou image pour generer la carte numerique

### Cote Supabase

- `Auth` pour les maries
- `Postgres` pour les donnees metier
- `Storage` pour :
  - videos
  - audios
  - cartes generees
  - assets graphiques
- `Row Level Security` pour proteger les donnees
- `Edge Functions` optionnelles pour :
  - valider le token du QR code
  - generer des liens securises
  - generer la carte cote serveur si necessaire

## 4. Modele de Donnees Supabase Recommande

### Tables principales

#### `profiles`
- `id`
- `role` : `admin`
- `full_name`
- `phone`
- `created_at`

#### `guests`
- `id`
- `full_name`
- `phone`
- `email`
- `qr_token`
- `status` : `pending`, `media_uploaded`, `card_unlocked`
- `created_at`

#### `tables`
- `id`
- `name`
- `description`
- `capacity`
- `created_at`

#### `chairs`
- `id`
- `table_id`
- `chair_number`
- `is_assigned`
- `created_at`

#### `guest_seats`
- `id`
- `guest_id`
- `table_id`
- `chair_id`
- `assigned_at`

#### `invitations`
- `id`
- `guest_id`
- `invitation_code`
- `qr_code_url`
- `card_url`
- `is_unlocked`
- `created_at`

#### `guest_media`
- `id`
- `guest_id`
- `media_type` : `audio` ou `video`
- `storage_path`
- `duration_seconds`
- `is_valid`
- `submitted_at`

### Buckets Storage

- `guest-audios`
- `guest-videos`
- `invitation-cards`
- `wedding-assets`

## 5. Structure Flutter Recommandee

```text
lib/
  app/
    data/
      models/
      providers/
      repositories/
    modules/
      auth/
      dashboard/
      tables/
      guests/
      invitations/
      qr_scan/
      media_capture/
      guest_access/
    routes/
    core/
      theme/
      services/
      utils/
  main.dart
```

### Modules GetX

- `AuthModule`
- `DashboardModule`
- `TablesModule`
- `GuestsModule`
- `InvitationsModule`
- `GuestAccessModule`
- `MediaCaptureModule`

## 6. Plan d'Implementation

### Phase 1. Cadrage et initialisation

- Creer le projet Flutter
- Ajouter GetX
- Configurer Supabase Flutter
- Definir les environnements `dev` et `prod`
- Mettre en place l'architecture modulaire

### Phase 2. Base de donnees Supabase

- Creer le schema SQL
- Creer les tables metier
- Configurer les buckets Storage
- Ecrire les policies RLS
- Prevoir les fonctions SQL ou Edge Functions utiles

### Phase 3. Authentification et espace maries

- Auth email/password pour les maries
- Ecran de connexion
- Tableau de bord d'administration
- Navigation principale

### Phase 4. Gestion des tables et chaises

- CRUD des tables
- Generation automatique des chaises selon capacite
- Vue d'occupation des places
- Attribution d'une chaise a un invite

### Phase 5. Gestion des invites

- CRUD des invites
- Association invite <-> table <-> chaise
- Statut de traitement de chaque invite
- Recherche et filtres

### Phase 6. Generation des invitations

- Creation de l'invitation apres attribution
- Generation d'un token unique
- Generation du QR code
- Creation de la carte numerique
- Stockage de la carte dans Supabase Storage

### Phase 7. Parcours invite

- Acces via QR code ou lien profond
- Verification du token
- Affichage des informations de l'invite
- Blocage de la carte tant que le media n'est pas fourni

### Phase 8. Capture audio/video

- Enregistrement audio
- Enregistrement video
- Controle local de la duree
- Upload vers Supabase Storage
- Enregistrement de la preuve dans `guest_media`
- Deblocage de la carte si la duree est validee

### Phase 9. Consultation et telechargement de la carte

- Affichage de la carte virtuelle
- Bouton de telechargement
- Bouton de partage
- Historique de validation cote maries

### Phase 10. Qualite et livraison

- Tests unitaires
- Tests widget
- Tests du flux principal
- Verification Android
- Verification iOS
- Preparation du build de production

## 7. Sprint MVP Recommande

### Sprint 1
- Initialisation Flutter + GetX
- Connexion Supabase
- Schema SQL
- Auth admin

### Sprint 2
- CRUD tables
- CRUD chaises
- CRUD invites
- Attribution des places

### Sprint 3
- Generation invitation
- QR code
- Page d'acces invite

### Sprint 4
- Enregistrement audio/video
- Verification 30 secondes
- Deblocage de la carte

### Sprint 5
- Telechargement carte
- Stabilisation
- Tests
- Livraison MVP

## 8. Risques Techniques a Anticiper

- Verification fiable de la duree reelle audio/video
- Permissions micro/camera selon Android et iOS
- Taille des fichiers video
- Generation de carte image ou PDF sur mobile
- Securisation du token QR
- Gestion hors ligne partielle

## 9. Decisions Recommandees Avant Developpement

- Choisir si l'invite accede via une route web, un deep link mobile ou les deux
- Choisir si la carte est une image PNG, un PDF ou une vue Flutter exportee
- Choisir si la validation des 30 secondes se fait seulement cote client ou aussi cote serveur
- Choisir si un invite peut renvoyer plusieurs medias ou un seul

## 10. Prompt Technique Pret a Reutiliser

Construire une application mobile Flutter avec GetX et Supabase pour la gestion d'invitations de mariage. L'application doit inclure un espace administrateur pour les maries afin de creer des tables, des chaises et des invites, attribuer une place a chaque invite et generer une carte d'invitation numerique avec QR code unique. Cote invite, l'utilisateur doit acceder a son invitation via QR code ou lien securise, enregistrer obligatoirement un audio ou une video d'au moins 30 secondes, puis seulement apres validation pouvoir consulter et telecharger sa carte d'invitation. Utiliser Supabase pour l'authentification des maries, la base de donnees, le stockage des medias et des cartes, avec une architecture Flutter modulaire basee sur GetX, repository pattern, routes dediees et securisation des acces via RLS.


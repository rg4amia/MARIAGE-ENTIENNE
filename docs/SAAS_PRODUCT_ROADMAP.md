# Feuille de route — SaaS d'organisation de mariages

## Positionnement

Une plateforme francophone qui accompagne un couple, un wedding planner ou une
agence depuis la préparation jusqu'au contrôle d'accès le jour du mariage.

## Phase 1 — Fondation commercialisable

- organisations clientes et collaborateurs ;
- plusieurs mariages et sélection du mariage actif ;
- packs mariage à paiement unique et abonnements professionnels
  (voir `OFFRE_COMMERCIALE.md`) ;
- inscription sur le pack gratuit, sans essai masqué ;
- lieux Mairie, Église et Réception avec coordonnées Maps ;
- identité visuelle par mariage : palettes prédéfinies, couleurs HEX et aperçu ;
- modèles de cartes personnalisables ;
- historique multicanal des envois ;
- tables, chaises et plan de salle enrichis ;
- RLS et contraintes anti-fuite entre clients.

## Phase 2 — Organisation quotidienne

- checklist intelligente avec échéances ;
- budget prévisionnel, dépenses et échéancier ;
- prestataires, devis, contrats et contacts ;
- programme de la journée et rappels ;
- rôles opérationnels pour témoins et coordinateurs.

## Phase 3 — Expérience invité

- RSVP par foyer avec accompagnants ;
- allergies, menus et besoins d'accessibilité ;
- cartes d'invitation web, image et PDF ;
- diffusion WhatsApp, email et SMS ;
- galerie privée, livre d'or audio/vidéo et remerciements.

## Phase 4 — Monétisation et supervision

Grille tarifaire et état d'avancement : voir `OFFRE_COMMERCIALE.md`.

- paiements Mobile Money et carte ;
- factures et renouvellements ;
- ~~quotas applicatifs imposés côté base~~ (fait : invités, envois,
  collaborateurs et forfait inactif) ;
- ~~console SaaS pour support, suspension et audit~~ (fait : voir
  `EXPLOITATION.md`) ;
- métriques de conversion, activation et rétention.

## Critères de passage en production de la phase 1

- tests RLS multi-organisation exécutés sur PostgreSQL local ;
- migration appliquée sur un environnement de préproduction ;
- onboarding Flutter vérifié sur Android, iOS et Web ;
- essai de création de deux organisations sans visibilité croisée ;
- sauvegarde et procédure de retour documentées ;
- aucune clé Maps ou paiement stockée dans le dépôt.

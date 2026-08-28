# ADR-001 — Socle SaaS multi-tenant pour l'organisation de mariages

## Statut

Accepté pour la phase 1 locale. La migration distante reste soumise à une validation explicite.

## Contexte

L'application actuelle gère correctement un mariage, ses invités, ses tables,
ses chaises et ses invitations. Elle associe toutefois chaque profil à un seul
`wedding_event` et utilise encore un identifiant d'événement fixe pendant
l'inscription. Ce contrat empêche de commercialiser le produit auprès de
plusieurs couples ou agences.

Le produit cible doit permettre :

- plusieurs organisations clientes isolées ;
- plusieurs mariages par organisation ;
- plusieurs organisateurs avec des droits différents ;
- des abonnements et limites de forfait ;
- des lieux typés et cartographiables ;
- plusieurs modèles de cartes d'invitation ;
- la traçabilité des envois ;
- la conservation intégrale du mariage et des invitations existants.

Hypothèses de dimensionnement : petite équipe produit, 1 000 à 100 000
utilisateurs, déploiement progressif en Afrique francophone et facturation
initiale en FCFA.

## Options considérées

| Option | Avantages | Inconvénients |
| --- | --- | --- |
| Une instance Supabase par client | Isolation physique forte | Coût et exploitation difficiles, migrations répétées |
| Microservices par domaine | Mise à l'échelle indépendante | Complexité prématurée pour l'équipe et le volume visés |
| PostgreSQL partagé avec frontière `organization_id` et RLS | Simple à exploiter, compatible avec l'existant, isolation testable | Demande des contraintes et policies RLS rigoureuses |

## Décision

Conserver Flutter, GetX et Supabase dans un monolithe modulaire. Introduire
`organizations` comme frontière commerciale, `organization_memberships` comme
frontière d'autorisation, et rattacher chaque `wedding_event` à une
organisation. Le profil conserve un mariage actif pour la compatibilité avec
les repositories actuels, mais peut basculer vers tout mariage autorisé de son
organisation.

Les lieux stockent un contrat cartographique indépendant du fournisseur
(`latitude`, `longitude`, `place_provider`, `place_id`, `maps_url`). Google Maps
ou Apple Maps pourront ainsi être branchés sans modifier le modèle métier.

## Arbitrages acceptés

- Une seule base PostgreSQL est partagée entre les clients ; l'isolation repose
  sur les clés étrangères composites, les fonctions sécurisées et la RLS.
- L'abonnement est modélisé maintenant, mais aucun paiement externe n'est
  exécuté dans cette phase.
- Le profil garde temporairement `event_id` en plus de `active_event_id` afin de
  ne pas casser les données et fonctions existantes.
- Les tâches, budgets, prestataires et paiements constituent les prochains
  modules ; ils ne doivent pas retarder la sécurisation multi-tenant.

## Conséquences

### Positives

- onboarding autonome d'un nouveau client ;
- isolation déterministe entre organisations ;
- prise en charge des couples et des agences ;
- migration progressive sans suppression de données ;
- intégration cartographique et paiement différables.

### Risques

- toute nouvelle table métier doit porter `event_id` ou `organization_id` et
  recevoir une policy RLS ;
- la migration distante doit être exécutée avec l'application d'onboarding
  compatible ;
- les limites de forfait devront être imposées dans les fonctions métier, pas
  seulement dans l'interface.

## Déclencheurs de réévaluation

- plus de 100 000 utilisateurs actifs ;
- équipe backend supérieure à dix développeurs ;
- besoin de mise à l'échelle indépendante pour les médias ou la facturation ;
- exigences réglementaires imposant une base dédiée par client.

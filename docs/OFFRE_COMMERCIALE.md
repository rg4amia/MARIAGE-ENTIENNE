# Offre commerciale

Marché de référence : Côte d'Ivoire et Afrique de l'Ouest francophone
(`country_code = CI`, `currency_code = XOF`, `timezone = Africa/Abidjan`).
Tous les montants sont en francs CFA.

## Pourquoi deux familles de tarifs

Un mariage n'est pas un abonnement. Un couple prépare pendant trois à six
mois, se marie une fois et s'en va. Le facturer au mois produit deux
comportements également mauvais : soit il tasse tout dans la période
d'essai puis résilie, soit il paie plusieurs mois avec le sentiment d'une
fuite. Un wedding planner, lui, a un flux continu de mariages : le
récurrent a du sens pour lui seul.

D'où deux grilles distinctes, et non une échelle unique.

## A. Packs mariage — paiement unique

| Pack | Prix | Invités | Invitations | Particularités |
|---|---|---|---|---|
| Essentiel | Gratuit | Illimités | 30 | Filigrane sur la carte |
| Mariage 150 | 35 000 F | 150 | 150 | Sans filigrane, couleurs et polices du couple |
| Mariage 300 | 60 000 F | 300 | 300 | 3 collaborateurs, support prioritaire |
| Mariage Illimité | 95 000 F | Illimités | Illimitées | 6 collaborateurs, export album HD |

Le gratuit n'est pas limité en invités : le couple doit pouvoir construire
son plan de salle en entier. C'est l'**envoi** des invitations qui est
compté, parce que c'est là que la valeur est délivrée.

## B. Abonnements professionnels

| Pack | Mensuel | Annuel | Mariages actifs | Collaborateurs |
|---|---|---|---|---|
| Planner | 20 000 F | 200 000 F | 5 | 5 |
| Agence | 55 000 F | 550 000 F | 25 | 25 |

L'annuel équivaut à dix mois payés pour douze.

Ces montants sont volontairement inférieurs à l'ancienne grille
(25 000 F et 75 000 F par mois) : 75 000 F/mois représente environ
115 €/mois, un tarif de SaaS occidental qu'une petite agence de la
sous-région ne signe pas.

## Les trois leviers de conversion

### L'ancrage face au carton imprimé

Le concurrent réel n'est pas une autre application, c'est l'imprimeur. Le
message à tenir sur la page de garde compare le pack au coût réel de
cartons physiques distribués à la main.

Tarifs publics relevés à Abidjan (août 2026) :

| Imprimeur | Produit | Prix unitaire |
|---|---|---|
| [Printxi](https://printxi.ci/vos-impressions-en-ligne/imprimez-vos-fichiers-en-ligne-sans-vous-deplacez/carte-dinvitation-20x10-recto/) | Carte d'invitation 20×10 recto, lot de 20 à 10 000 F | ~500 F |
| [Klas Events](https://klasevents225.com/en/produit/faire-part-mariage/) | Faire-part mariage | 1 200 F (promo, 1 800 F hors promo) |

Ancrage retenu, volontairement prudent : **500 F par carton**, soit le bas
de la fourchette. Un mariage de 300 invités représente donc au moins
150 000 F de cartons, hors distribution — contre 60 000 F pour le pack
Mariage 300, soit environ **200 F par invité**.

> Ces relevés sont des prix affichés en ligne, pas des devis négociés pour
> un tirage précis. Les revalider avant toute campagne payante, et ne
> jamais afficher un chiffre au-dessus de 500 F/carton sans devis écrit.

### Le moment du paiement

Le mur payant tombe au 31ᵉ envoi d'invitation, jamais à l'inscription. Le
couple a alors déjà construit ses tables, placé ses invités et choisi ses
couleurs : l'effort est investi. Le bandeau d'alerte apparaît dès 70 % du
quota consommé, pour prévenir avant de bloquer.

Corollaire : pas de période d'essai chronométrée pour les couples. Le pack
gratuit ne périme pas.

### Le paiement mobile

Orange Money, Wave, MTN MoMo et Moov Money sont indispensables. La carte
bancaire seule écraserait la conversion sur ce marché.

## État d'implémentation

| Élément | État |
|---|---|
| Catalogue en base et reprise de l'ancienne grille | Fait |
| Inscription sur le pack gratuit, sans essai masqué | Fait |
| `get_subscription_overview()` : forfait + consommation réelle | Fait |
| Page de garde, splash, inscription, écran Tarifs | Fait |
| Bandeau de quota sur le tableau de bord | Fait |
| Quotas **imposés** côté base (triggers de refus) | Fait |
| Envois décomptés depuis l'app (`record_invitation_delivery`) | Fait |
| Filigrane du pack gratuit sur la carte de l'invité | Fait |
| Encaissement Mobile Money et renouvellements | À faire |
| Expiration automatique des essais professionnels | Fonction prête, ordonnancement à faire |

Trois déclencheurs refusent désormais l'opération de trop, avec un message
en français que l'application affiche telle quelle avant de proposer le
pack supérieur : `enforce_guest_quota`, `enforce_invitation_quota` et
`enforce_collaborator_quota`. Un forfait `past_due`, `canceled` ou
`suspended` bloque tout envoi.

### Ce qui empêche de remettre le compteur à zéro

La consommation d'envois ne vit plus dans `invitation_deliveries` — que
l'organisateur gère, et que la suppression d'une invitation vidait en
cascade — mais dans `invitation_quota_ledger`, un registre en ajout seul
sans clé étrangère vers `invitations`. Un envoi parti chez l'invité reste
consommé, comme un timbre collé, même si l'invitation est ensuite
supprimée ou l'invité déplacé.

En conséquence :

- l'organisateur ne peut plus ni modifier ni supprimer ses lignes d'envoi
  (la politique `ALL` est remplacée par `SELECT` + `INSERT`) ;
- supprimer une invitation, désassigner une place ou supprimer un invité
  ne rend pas d'envoi ;
- une relance reste gratuite : le registre est unique par invitation ;
- le quota d'invités s'applique aussi au **déplacement** d'un invité vers
  un autre mariage, pas seulement à sa création ;
- toute organisation reçoit un forfait à sa création
  (`trg_organizations_default_subscription`), y compris hors du parcours
  d'inscription : il n'existe plus d'espace hors quota.

Deux limites assumées :

- supprimer entièrement un mariage efface son registre. Cela détruit tout
  le travail du couple et reste borné par `max_events` (1 sur les packs) ;
  le jeu n'en vaut pas la chandelle, mais le trou existe.
- `expire_stale_subscriptions()` n'est planifiée que si `pg_cron` est
  installé. Sans lui, un essai professionnel expiré reste `trialing` en
  base, mais `effective_subscription_status()` le requalifie à la lecture
  et le blocage à l'envoi est effectif malgré tout.

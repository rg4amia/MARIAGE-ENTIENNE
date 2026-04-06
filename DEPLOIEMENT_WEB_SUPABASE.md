# Deploiement Web + Supabase

## Etat actuel

- Le projet Flutter web est branche sur Supabase `sckvfrsjmbwkuqdfsgki`.
- La base distante a recu les migrations SQL et le seed.
- Le parcours invite web utilise maintenant Supabase via RPC public par token.
- Les liens QR web utilisent le format `/#/guest/{token}` pour fonctionner sur un hebergement statique sans regles de rewrite serveur.

## Bundle web

Le build de production Flutter web est genere dans :

- `mobile_app/build/web`

## Invitation de demonstration

Une invitation de test existe deja dans Supabase :

- invite : `Stephanie K.`
- token : `stephanie-k-001`
- route web attendue apres hebergement : `https://votre-domaine/#/guest/stephanie-k-001`

## Ce que fait deja le parcours invite web

- ouverture via QR code
- acces sans installation d'application
- enregistrement audio dans le navigateur
- enregistrement video via le navigateur ou la camera du mobile
- validation 30 secondes cote client et cote base
- telechargement de la carte PNG/PDF depuis la page invite

## Limite restante

Le build est pret, mais la publication sur une URL publique depend encore d'un hebergeur web statique externe, par exemple :

- Vercel
- Netlify
- GitHub Pages
- Firebase Hosting
- un serveur Nginx

Supabase dans cette configuration sert la base, l'auth, le storage et les fonctions SQL/RPC, mais pas l'hebergement statique Flutter web via ce CLI.

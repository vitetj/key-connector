# Pilote Vaultwarden + Key Connector sur Cloudron (TEST)

> ⚠️ **TEST UNIQUEMENT.** Fork non officiel (PR #7419 non mergée), migration de base irréversible,
> pas de retour du Key Connector vers le mot de passe maître. Ne jamais pointer sur la base de l'app `vault` de prod.
> Idéalement sur un Cloudron de test, pas sur cloudronprod.

## Contenu
- racine du dépôt : package Cloudron du Key Connector [acul021/key-connector](https://github.com/acul021/key-connector),
  compilé depuis les sources (commit épinglé dans `Dockerfile`), SQLite dans `/app/data`
- `vaultwarden-kc/` : package Cloudron du fork Vaultwarden `ghcr.io/acul021/vaultwarden:testing` (amd64), SQLite dans `/app/data`

## 1. Entra ID — App registration
1. Nouvelle app « Vaultwarden KC TEST », comptes de ce tenant uniquement.
2. Redirect URI (Web) : `https://vaultkc.ixapack.io/identity/connect/oidc-signin`
3. Secret client → `SSO_CLIENT_SECRET`.
4. API permissions déléguées : `openid`, `email`, `profile`, `offline_access` + consentement admin.
5. Restreindre l'accès au groupe pilote (Enterprise app → *Assignment required* = Oui) + MFA / accès conditionnel.

## 2. Installation (sans build)
Les images sont construites par GitHub Actions à chaque push sur `main` et publiées sur `ghcr.io/vitetj/key-connector`
et `ghcr.io/vitetj/vaultwarden-kc`. Dans le Cloudron de test : **App Store → Community apps → Add**, puis coller :

```
https://raw.githubusercontent.com/vitetj/key-connector/main/CloudronVersions.json
```
```
https://raw.githubusercontent.com/vitetj/key-connector/main/vaultwarden-kc/CloudronVersions.json
```

Installer ensuite les deux apps depuis l'App Store (par ex. `keyconnector-test` et `vaultkc`).
Les deux apps démarrent puis s'arrêtent volontairement (garde-fou `CHANGEME`) : c'est normal.

Pour sortir une nouvelle version : bumper `version` dans le `CloudronManifest.json` concerné et dans son
`CloudronVersions.json` (nouvelle entrée avec `dockerImage` sur le nouveau tag), puis pousser sur `main`.

<details><summary>Build manuel (optionnel, Cloudron CLI + Docker)</summary>

```bash
npm install -g cloudron
cloudron login my.ixapack.io
cloudron build --repository registry.ixapack.io/ixapack/key-connector && cloudron install --location keyconnector-test
cd vaultwarden-kc
cloudron build --repository registry.ixapack.io/ixapack/vaultwarden-kc && cloudron install --location vaultkc
```
</details>

## 3. Configuration
**Vaultwarden KC** — éditer `/app/data/env` (File manager ou Terminal de l'app) :
`ADMIN_TOKEN`, `SSO_AUTHORITY` (tenant ID), `SSO_CLIENT_ID`, `SSO_CLIENT_SECRET`,
`KEY_CONNECTOR_URL=https://keyconnector-test.ixapack.io` → redémarrer.

**Key Connector** — option A recommandée (clé statique, aucun flux KC → Vaultwarden) :
1. Terminal de l'app Vaultwarden KC : `openssl rsa -in /app/data/rsa_key.pem -pubout`
2. Coller le résultat dans `/app/data/identity.pub.pem` de l'app Key Connector.
3. Dans son `/app/data/env` : `KC_JWT_ISSUER="https://vaultkc.ixapack.io|login"` (guillemets obligatoires à cause du `|`) et
   `KC_CORS_ALLOWED_ORIGINS=https://vaultkc.ixapack.io` → redémarrer.

## 4. Scénario de test
1. Créer un compte **admin** (exempté → garde un mot de passe maître), créer l'organisation de test.
2. Inviter un compte **utilisateur** pilote → connexion SSO → écran « utiliser le Key Connector Ixapack TEST »
   → aucun mot de passe maître demandé.
3. Vérifier : web vault, extension navigateur, appli Android/iOS, desktop (déverrouillage après redémarrage).
4. Couper l'app Key Connector → l'utilisateur ne doit plus pouvoir déverrouiller ; l'admin si.
5. Restaurer une sauvegarde Cloudron des **deux** apps → l'utilisateur doit retrouver son coffre.
6. Après chaque mise à jour des clients Bitwarden : rejouer 2 et 3.

## 5. Limites connues de ce packaging
- La clé de chiffrement du KC est générée dans `/app/data` → **elle part dans la même sauvegarde que la base**.
  Acceptable en test, pas en prod (clé à fournir depuis un secret store, ex. OpenBao).
- Tag `testing` mouvant : épingler le digest dans `vaultwarden-kc/Dockerfile` une fois validé.
- Le Key Connector est construit sur le commit `KC_COMMIT` de `Dockerfile` (HEAD de `main` au 03/11/2026) : à mettre à jour volontairement, jamais en suivant `main` à l'aveugle.
- Publication externe (App Proxy) : mode passthrough uniquement, pas de pré-authentification.

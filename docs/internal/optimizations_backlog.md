# Backlog optimisations infra & UX

> **Statut** : internal
> **Public cible** : équipe dev / ops
> **Dernière mise à jour** : 2026-04-27
> **Provenance** : ex-`docs/operations/optimizations_backlog.md`, déplacé dans `docs/internal/` car backlog équipe sans source de vérité code.
>
> **Backlog** d'améliorations infra (Docker, GitHub Actions, sécurité) et UX
> identifiées au fil des sessions ops.
> Les items non cochés restent à arbitrer ; pour le **plan produit** se référer
> à [`todo.md`](todo.md).

Les sections « Documentation » historiques renvoient à des fichiers supprimés
ou renommés (`KNOWLEDGE_BASE.md`, `DEPLOYMENT_GUIDE.md`) — désormais consolidés
dans [`../operations/deployment.md`](../operations/deployment.md).

## ✅ Réalisé le 14/10/2025

- [x] **Optimisation du module Horaires d'ouverture** :
  - Fix des messages flash dupliqués
  - Ajout d'un message d'erreur rouge pour la validation
  - Simplification du JavaScript (suppression de la complexité importmap)
  - Amélioration de l'UX avec aperçu en temps réel
  - Correction des fonctionnalités checkbox et sélecteurs
  - Nettoyage du contrôleur pour une meilleure gestion des erreurs

## À faire : Optimisations Adhérents

- [x] Déplacer le(s) bouton(s) d'import/export :  
  Mettre les boutons d'import et d'export directement sur la page de liste des adhérents.

- [x] Nettoyer le menu d'administration :  
  Retirer les liens "ajouter un adhérent" et "export" du menu d'administration (puisqu'ils existent déjà sur la liste des adhérents).

- [ ] Harmoniser les termes :  
  Remplacer tous les libellés "utilisateur" par "adhérent" dans l'application (front/boutons/messages).

- [x] Rendre le champ mail optionnel :  
  Permettre l'ajout d'adhérent sans email lorsque l'action est réalisée par un administrateur.

- [x] RGPD - Newsletter :  
  Désactiver la possibilité d'inscrire un adhérent à la newsletter depuis le menu d'administration.


## À faire : Divers (autres optimisations)

- [x] Wording :  
  Renommer le lien "retourner sur le site" par "voir le site".

- [x] Séparer Horaires du menu adhérents :  
  Donner une entrée dédiée dans le menu d'administration pour le formulaire des horaires (actuellement accessible depuis la liste des adhérents).

- [ ] Fusion de plusieurs pages informatives :  
  Regrouper les sections suivantes sur une seule page :
  - Le lieu
  - Par qui / pourquoi / pour qui  
  Suggestions pour la hiérarchie d'information :
    - Présenter d'abord Circographe (le lieu)
    - Ensuite les activités (pour qui/pourquoi)
    - Enfin l'équipe  
    **Ou**  
    - Activités, puis lieu, puis équipe (équipe en dernier)

- [ ] Fusionner contact et "nous trouver" :  
  Mettre le formulaire de contact et les informations pour nous trouver sur une seule page.

- [x] UX admin :  
  Sur le site principal, détacher le lien d'accès au back-office d'administration du menu de profil utilisateur lorsqu'on est connecté en tant qu'admin.


## ✅ Priorité 1: Corrections Immédiates (< 30 min)

### 1.1 Fixer Version Bundler dans Dockerfile
```dockerfile
# Dans Dockerfile, ligne 32, après FROM base AS build
FROM base AS build

# Fix Bundler version to match Gemfile.lock
RUN gem install bundler:2.5.23

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
```

**Fichier:** `Dockerfile`  
**Gain:** Évite réinstallation Bundler à chaque build (~5-10s)

---

### 1.2 Utiliser docker/login-action dans GitHub Actions
```yaml
# Remplacer dans .github/workflows/03-staging-deploy.yml
# Ancien:
- name: Login to GHCR
  run: echo "$KAMAL_REGISTRY_PASSWORD" | docker login ghcr.io -u AkaKwak --password-stdin

# Nouveau:
- name: Login to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

**Fichier:** `.github/workflows/03-staging-deploy.yml`  
**Gain:** Sécurité améliorée, credentials chiffrées

---

## ⚡ Priorité 2: Optimisations Performance (1-2h)

### 2.1 Ajouter Docker Build Cache dans GitHub Actions
```yaml
# Dans .github/workflows/03-staging-deploy.yml
# Remplacer la step "Build Docker image for staging"

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build and push Docker image
  uses: docker/build-push-action@v6
  with:
    context: .
    push: true
    tags: ghcr.io/lecircographe-asso/circographe-staging:${{ github.sha }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
    build-args: |
      RUBY_VERSION=3.2.5
```

**Fichier:** `.github/workflows/03-staging-deploy.yml`  
**Gain:** 40-60% réduction temps de build (2min → 45s)

---

### 2.2 Réorganiser Dockerfile pour Meilleur Cache
```dockerfile
# Ordre optimal pour maximiser le cache
FROM base AS build

# 1. Fixer version Bundler (change rarement)
RUN gem install bundler:2.5.23

# 2. Dépendances système (change rarement)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 3. Gems (change moyennement) - AVANT le code
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# 4. Code application (change souvent) - APRÈS les gems
COPY . .

# 5. Precompilation (dépend du code)
RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE="a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2" \
    RAILS_ENV=staging \
    ./bin/rails assets:precompile
```

**Fichier:** `Dockerfile`  
**Gain:** Cache layers gems réutilisé si Gemfile.lock inchangé

---

### 2.3 Optimiser Nettoyage Gems
```dockerfile
# Dans Dockerfile, améliorer le nettoyage après bundle install
RUN bundle install && \
    rm -rf ~/.bundle/ \
    "${BUNDLE_PATH}"/ruby/*/cache \
    "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git \
    "${BUNDLE_PATH}"/ruby/*/gems/*/test \
    "${BUNDLE_PATH}"/ruby/*/gems/*/spec \
    "${BUNDLE_PATH}"/ruby/*/gems/*/examples \
    && bundle exec bootsnap precompile --gemfile
```

**Fichier:** `Dockerfile`  
**Gain:** Réduction taille image (~10-20MB)

---

## 🔒 Priorité 3: Sécurité (1h)

### 3.1 Configurer Docker Credential Helper sur VPS
```bash
# SSH sur le VPS
ssh deploy@$STAGING_SERVER_IP

# Installer pass
sudo apt-get update
sudo apt-get install -y pass gnupg2

# Initialiser GPG key
gpg --gen-key
# Suivre les instructions

# Configurer docker-credential-pass
pass init "your-gpg-key-id"
docker-credential-pass initialize

# Tester
echo "test" | docker-credential-pass store test
docker-credential-pass get test
```

**Serveur:** VPS Staging + Production  
**Gain:** Sécurité credentials Docker

---

## 📝 Priorité 4: Documentation (30 min)

### 4.1 Documenter Source Maps Manquantes
```markdown
# Dans KNOWLEDGE_BASE.md, ajouter section:

### **Assets Source Maps (Optionnel)**
Les warnings suivants sont normaux en production:
- `swiper-bundle.min.js.map` - Source map Swiper
- `flowbite.min.js.map` - Source map Flowbite  
- `image.svg` - Image placeholder Tailwind

**Action:** Aucune requise - Source maps non nécessaires en production
**Si debugging requis:** Ajouter les .map files dans vendor/javascript/
```

**Fichier:** `KNOWLEDGE_BASE.md`  
**Gain:** Clarté pour futurs développeurs

---

### 4.2 Ajouter Métriques de Performance
```markdown
# Dans DEPLOYMENT_GUIDE.md, ajouter section:

## 📊 Métriques de Performance

### Temps de Déploiement Typique
- **Build GitHub Actions:** ~2 min
- **Deploy Kamal:** ~2 min
- **Total:** ~4 min

### Objectifs Optimisés
- **Build (avec cache):** ~45s
- **Deploy:** ~30s
- **Total:** ~1min 15s
```

**Fichier:** `DEPLOYMENT_GUIDE.md`  
**Gain:** Suivi performance déploiements

---

## 🎯 Plan d'Implémentation Recommandé

### Phase 1 - Quick Wins (Aujourd'hui)
1. ✅ Fixer version Bundler (5 min)
2. ✅ Utiliser docker/login-action (10 min)
3. ✅ Tester déploiement (15 min)

### Phase 2 - Performance (Cette semaine)
4. ⚡ Ajouter Docker build cache (30 min)
5. ⚡ Réorganiser Dockerfile (30 min)
6. ⚡ Tester et mesurer gains (30 min)

### Phase 3 - Sécurité (Semaine prochaine)
7. 🔒 Configurer credential helper VPS (1h)
8. 🔒 Vérifier sécurité complète (30 min)

### Phase 4 - Documentation (Quand temps disponible)
9. 📝 Documenter source maps (15 min)
10. 📝 Ajouter métriques (15 min)

---

## 📈 Gains Attendus

| Optimisation | Temps Gagné | Complexité | ROI |
|--------------|-------------|------------|-----|
| Bundler version | ~10s | Faible | ⭐⭐⭐ |
| docker/login-action | Sécurité | Faible | ⭐⭐⭐ |
| Docker build cache | ~1-2min | Moyenne | ⭐⭐⭐⭐⭐ |
| Dockerfile réorganisé | ~30s | Moyenne | ⭐⭐⭐⭐ |
| Credential helper | Sécurité | Moyenne | ⭐⭐⭐ |

**Total estimé:** ~70% réduction temps de déploiement + sécurité améliorée

---

## ✅ Checklist Avant Implémentation

- [ ] Backup configuration actuelle (git commit)
- [ ] Lire documentation Docker build cache
- [ ] Tester sur branche dédiée d'abord
- [ ] Mesurer temps de build AVANT optimisations
- [ ] Mesurer temps de build APRÈS optimisations
- [ ] Documenter résultats dans DEPLOYMENT_ANALYSIS.md
- [ ] Merger si gains confirmés

---

**Créé le:** 2025-10-12  
**Statut:** 🟡 En attente d'implémentation  
**Prochaine action:** Phase 1 - Quick Wins

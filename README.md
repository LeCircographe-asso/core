# Le Circographe

Application de gestion pour l'association Le Circographe à Toulouse.

## Description

Le Circographe est une application qui permet de gérer :
- Les adhésions (basique et cirque)
- Les abonnements d'accès à la pratique
- Les présences aux entraînements
- Les paiements et la comptabilité
- Les statistiques de fréquentation

## Structure du Projet

### Documentation
- `README.md` - Vue d'ensemble et guide de démarrage
- `ARCHITECTURE.md` - Documentation technique détaillée
- `USER_STORIES.md` - Cas d'utilisation par type d'utilisateur
- `ROADMAP.md` - Plan de développement et phases

### Logique Métier

#### Types d'Adhésion
- **Adhésion Basique** (1€/an)
  - Permet d'être visiteur aux entraînements
  - Accès aux événements

- **Adhésion Cirque** (10€/an)
  - Permet d'acheter des abonnements
  - Tarif réduit : 7€ (étudiant, RSA, handicap)

#### Types d'Abonnement
- Pass Journée (4€)
- Carnet 10 séances (30€)
- Trimestriel (65€)
- Annuel (150€)

### Stack Technique
- Ruby on Rails 8.0.1
- Hotwire (Turbo + Stimulus)
- SQLite3
- PWA (Progressive Web App)

## Installation

### Prérequis
- Ruby 3.x
- Rails 8.0.1
- SQLite3
- Node.js et Yarn

### Mise en place
```bash
# Cloner le repository
git clone https://github.com/Team-stash/le_circographe.git
cd le_circographe

# Installer les dépendances
bundle install
yarn install

# Configurer la base de données
rails db:create db:migrate db:seed

# Lancer l'application
rails assets:clobber
./bin/dev
rails server
```

## Développement

### Branches
- `main` - Production
- `develop` - Développement
- `BDD001` - Refonte du modèle de données

### Points d'Attention
1. **Modèle de Données**
   - Séparation possible membres/abonnements
   - Migration progressive envisagée
   - Voir `ARCHITECTURE.md` pour plus de détails

2. **Tests**
   - Couverture requise pour la logique métier
   - Tests d'intégration pour les workflows critiques

3. **Documentation**
   - Maintenir `ARCHITECTURE.md` à jour
   - Documenter les changements d'API

## Équipe

### Mentor
- Hadrien SAMOUILLAN

### Développeurs
- Christophe Alaterre (@AkaKwak)
- Thierry Corlieto (@hellijah)
- Florian Elie (@Elie-Kauptairr)
- Luc Ramassamy (@Warzieram)
- Sacha Courbé (@Sachathp)

## Contribution

1. Créer une branche (`git checkout -b feature/ma-feature`)
2. Commit (`git commit -m 'Description'`)
3. Push (`git push origin feature/ma-feature`)
4. Créer une Pull Request

## Licence

Ce projet est la propriété de l'association Le Circographe.

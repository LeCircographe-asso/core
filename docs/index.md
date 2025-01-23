# Documentation Le Circographe - Gestion des Entraînements

## 📚 Table des Matières

1. [Présentation](#présentation)
2. [Guide Technique](#guide-technique)
3. [Roadmap](#roadmap)
4. [Tests](#tests)

## 📖 Documentation Complète

### Présentation
- [Présentation du Système](presentation_entrainements.md)
  - Objectifs
  - Interface Administrateur
  - Workflow Quotidien
  - Rapports et Statistiques
  - Avantages
  - Évolutions Prévues

### Guide Technique
- [Guide d'Installation](training_feature_readme.md)
  - Installation et Configuration
  - Utilisation
  - Tâches Rake
  - Tests
  - Routes Disponibles

### Roadmap
- [Plan de Développement](training_system_roadmap.md)
  - Modèles et Migrations
  - Logique Métier
  - Interface Admin
  - Tests

### Tests
- [Tests Système](../spec/system/training_management_spec.rb)
  - Tests du Dashboard
  - Tests de Gestion des Membres
  - Tests d'Adhésion

## 🗂 Structure des Fichiers

```
docs/
├── index.md                      # Ce fichier
├── presentation_entrainements.md # Présentation pour les partenaires
├── training_feature_readme.md    # Guide technique
└── training_system_roadmap.md    # Plan de développement

spec/
└── system/
    └── training_management_spec.rb # Tests système

lib/
└── tasks/
    └── training.rake              # Tâches automatisées
```

## 🚀 Démarrage Rapide

1. **Installation**
```bash
# Cloner le projet
git clone [URL_DU_PROJET]

# Installer les dépendances
bundle install

# Créer et migrer la base de données
rails db:create db:migrate

# Installer whenever pour les tâches cron
bundle exec whenever --update-crontab
```

2. **Configuration**
```ruby
# config/schedule.rb
every 1.day, at: '00:00' do
  rake 'training:daily_maintenance'
end
```

3. **Lancement**
```bash
# Démarrer le serveur
rails s

# Accéder au dashboard
open http://localhost:3000/admin/entrainements
```

## 📝 Notes Importantes

1. **Sécurité**
   - Accès restreint aux administrateurs
   - Vérification des adhésions
   - Protection CSRF

2. **Performance**
   - Cache des statistiques
   - Eager loading des associations
   - Indexes optimisés

3. **Maintenance**
   - Tâches automatisées
   - Génération de rapports
   - Sauvegarde des données

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/ma-feature`)
3. Commit les changements (`git commit -am 'Ajout de ma feature'`)
4. Push la branche (`git push origin feature/ma-feature`)
5. Créer une Pull Request

## 📫 Support

Pour toute question ou suggestion :
- Ouvrir une issue
- Contacter l'équipe technique 
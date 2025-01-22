# Checklist Pré-Production Circographe

## 1. Tests et Validation
- [ ] Lancer tous les tests : `rails test:features`
- [ ] Vérifier la couverture de tests : `COVERAGE=true bundle exec rspec`
- [ ] Tester manuellement les workflows critiques :
  - [ ] Inscription membre
  - [ ] Adhésion à 1€
  - [ ] Passage quotidien
  - [ ] Interface bénévole

## 2. Sécurité
- [ ] Vérifier les autorisations (Pundit policies)
- [ ] Sécuriser les routes admin
- [ ] Configurer les variables d'environnement
- [ ] Mettre à jour les gems sensibles

## 3. Performance
- [ ] Optimiser les requêtes N+1
- [ ] Ajouter les index nécessaires :
  ```ruby
  rails generate migration AddIndexesToCriticalTables
  ```
- [ ] Mettre en place le caching :
  - Fragments pour les listes
  - Russian Doll pour les modèles imbriqués

## 4. Base de Données
- [ ] Vérifier les migrations
- [ ] Créer les données de base :
  ```ruby
  rails db:seed RAILS_ENV=production
  ```
- [ ] Backup de la base de développement
- [ ] Plan de backup automatique

## 5. Configuration Production
- [ ] Configurer le serveur (nginx/puma)
- [ ] Mettre en place SSL
- [ ] Configurer les logs
- [ ] Monitoring (Exception Notifier)

## 6. Documentation
- [ ] Guide utilisateur bénévole
- [ ] Documentation technique
- [ ] Procédures de backup/restore
- [ ] Plan de maintenance

## 7. Déploiement
```bash
# 1. Préparation
git checkout main
git merge dev
git push origin main

# 2. Base de données
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed

# 3. Assets
RAILS_ENV=production rails assets:precompile

# 4. Serveur
sudo service nginx restart
sudo systemctl restart puma
```

## 8. Post-Déploiement
- [ ] Vérifier les logs
- [ ] Tester les fonctionnalités critiques en production
- [ ] Monitorer les performances
- [ ] Backup initial complet

## 9. Plan de Rollback
```bash
# En cas de problème
git revert HEAD
RAILS_ENV=production rails db:rollback
sudo systemctl restart puma
```

## 10. Contacts d'Urgence
- Support Technique : [contact]
- Admin Système : [contact]
- Responsable Projet : [contact] 
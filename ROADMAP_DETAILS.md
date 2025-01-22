# Roadmap Détaillée du Circographe

## Phase 1 : Modèles Fondamentaux (Semaine 1)

### 1.1 Adhésions
- [x] SubscriptionType (existant)
  - Types : daily, booklet, trimestrial, annual
  - Prix et durées configurés

- [ ] MembershipType (à créer)
  ```ruby
  rails generate model MembershipType name:string price:decimal duration:integer category:string
  ```
  - Basic (1€/an)
  - Circus (25€/an)

### 1.2 Passages
- [ ] TrainingAttendee (à créer)
  ```ruby
  rails generate model TrainingAttendee user:references training_session:references
  ```
  - Lien avec l'utilisateur
  - Lien avec la session
  - Suivi des présences

### 1.3 Dons
- [ ] Donation (à créer)
  ```ruby
  rails generate model Donation user:references amount:decimal notes:text
  ```
  - Système de dons flexible
  - Traçabilité des paiements

## Phase 2 : Interface Admin (Semaine 2-3)

### 2.1 Dashboard Bénévole
- [ ] Vue principale des passages
- [ ] Recherche rapide de membres
- [ ] Actions rapides (adhésion, passage)

### 2.2 Gestion des Adhésions
- [ ] Workflow d'inscription unifié
- [ ] Bypass événement (adhésion 1€)
- [ ] Conversion membership → circus

## Phase 3 : Optimisation (Semaine 4)

### 3.1 Nettoyage et Validation
- [ ] Suppression des doublons
- [ ] Validation des données
- [ ] Tests automatisés

### 3.2 Documentation
- [ ] Guide utilisateur
- [ ] Documentation technique
- [ ] Procédures bénévoles

## Points de Contrôle

### Avant Production
- [ ] Vérification des modèles (`rails setup:check`)
- [ ] Nettoyage des données (`rails setup:clean`)
- [ ] Tests de bout en bout

### Post-Déploiement
- [ ] Formation des bénévoles
- [ ] Période de test avec utilisateurs
- [ ] Ajustements basés sur retours

## Notes Importantes

### Priorités
1. Interface bénévole fonctionnelle
2. Gestion des adhésions fiable
3. Système de passages robuste

### Points d'Attention
- Garder l'interface simple pour les bénévoles
- Assurer la traçabilité des paiements
- Maintenir la flexibilité du système 
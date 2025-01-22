# Diagnostic du Circographe

## 1. État Actuel des Fonctionnalités

### ✅ Éléments en Place
1. Structure de Base
   - Session management
   - Système de rôles (guest → membership → circus_membership)
   - Modèle User avec validations
   - Dashboard admin de base

2. Gestion des Accès
   - Vérification des rôles
   - Validation des adhésions
   - Contrôle des accès de base

### ❌ Éléments Manquants
1. Modèles Critiques
   - TrainingAttendee (passages quotidiens)
   - SubscriptionType (types d'abonnements)
   - AdminController (base admin)

2. Fonctionnalités Core
   - Interface bénévole complète
   - Workflow d'inscription unifié
   - Gestion des paiements
   - Système de bypass événements

## 2. Priorités d'Implémentation

### Priorité 1 : Core Business (Sprint 1-2)
1. Modèles Fondamentaux
   ```ruby
   rails generate model TrainingAttendee user:references training_session:references user_membership:references recorded_by:references
   rails generate model SubscriptionType name:string price:decimal duration:integer description:text
   ```

2. Interface Bénévole
   - [ ] Vue principale des passages
   - [ ] Recherche rapide de membres
   - [ ] Validation des accès

3. Workflow d'Inscription
   - [ ] Formulaire unifié (membership/circus)
   - [ ] Gestion des paiements
   - [ ] Bypass événements (adhésion 1€)

### Priorité 2 : Administration (Sprint 3-4)
1. Structure Admin
   ```ruby
   rails generate controller Admin::Base
   rails generate controller Admin::Members
   rails generate controller Admin::Payments
   ```

2. Dashboard
   - [ ] Vue d'ensemble des passages
   - [ ] Gestion rapide des adhésions
   - [ ] Statistiques basiques

### Priorité 3 : Validation et Sécurité (Sprint 5)
1. Validations
   - [ ] Vérification des paiements
   - [ ] Contrôle des doublons
   - [ ] Audit des actions

2. Navigation
   - [ ] Règles par rôle
   - [ ] Redirections automatiques
   - [ ] Permissions granulaires

## 3. Roadmap Détaillée

### Phase 1 : Fondations (Semaine 1-2)
1. Modèles et Migrations
   ```bash
   rails generate model TrainingAttendee
   rails generate model SubscriptionType
   rails db:migrate
   ```

2. Controllers Essentiels
   ```ruby
   # app/controllers/admin/training_sessions_controller.rb
   def add_attendee
     @user = User.find(params[:user_id])
     if @user.can_train_today?
       @session.add_attendee!(@user)
       redirect_to admin_training_sessions_path
     end
   end
   ```

### Phase 2 : Interface (Semaine 3-4)
1. Vues Principales
   ```erb
   # app/views/admin/training_sessions/index.html.erb
   # app/views/admin/members/_registration_form.html.erb
   # app/views/admin/dashboard/_quick_actions.html.erb
   ```

2. Stimulus Controllers
   ```javascript
   // app/javascript/controllers/registration_controller.js
   // app/javascript/controllers/search_controller.js
   ```

### Phase 3 : Optimisation (Semaine 5-6)
1. Validations et Sécurité
2. Tests et Documentation
3. Optimisations UI/UX

## 4. Points d'Attention

### Technique
- Gérer les transactions pour les paiements
- Éviter les problèmes de concurrence
- Maintenir un audit trail

### Utilisateur
- Interface simple pour les bénévoles
- Messages d'erreur clairs
- Workflow intuitif

### Business
- Flexibilité des adhésions
- Traçabilité des paiements
- Statistiques utiles

## 5. Prochaines Actions Immédiates

1. Créer les modèles manquants
2. Implémenter l'interface bénévole basique
3. Mettre en place le workflow d'inscription
4. Tester les cas d'usage principaux 

rails console
irb> SubscriptionType.pluck(:name)
=> ["daily", "booklet", "trimestrial", "annual"] 
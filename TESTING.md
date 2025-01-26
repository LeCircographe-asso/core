# Stratégie de Test - Le Circographe

## 1. Tests Unitaires

### Modèle User
- Validation des rôles et permissions
- Gestion des adhésions et abonnements
- Historique des présences
- Changements de statut

### Modèle SubscriptionType
- Validation des prix fixes
- Compatibilité des abonnements
- Durées et limitations
- Statuts actif/inactif

### Modèle UserMembership
- Validation des dates
- Unicité des adhésions actives
- Gestion des renouvellements
- Historisation des changements

### Modèle TrainingAttendee
- Validation des présences
- Décompte des sessions
- Règles de compatibilité
- Types de présence

### Modèle Payment
- Validation des montants
- Gestion des dons
- Statuts de paiement
- Traçabilité

## 2. Validations Métier

### Adhésions
```ruby
validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
validate :validate_subscription_prices
validate :one_active_membership_per_type
```

### Abonnements
```ruby
validates :start_date, :end_date, presence: true
validate :end_date_after_start_date
validate :validate_no_active_subscription_with_day_pass
```

### Présences
```ruby
validates :user_id, uniqueness: { scope: [:check_in_time] }
validate :user_has_valid_membership
validate :validate_practice_requirements
validate :session_is_open
```

### Paiements
```ruby
validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
validates :payment_method, presence: true
validates :status, presence: true
```

## 3. Scénarios de Test

### Parcours Utilisateur
1. Création de compte
2. Achat adhésion simple
3. Upgrade vers adhésion cirque
4. Achat d'abonnement
5. Enregistrement présence
6. Consultation historique

### Gestion Administrative
1. Création de session
2. Enregistrement présences
3. Génération statistiques
4. Gestion des rôles
5. Modification abonnements

### Cas Limites
1. Expiration d'adhésion
2. Épuisement carnet
3. Conflit d'abonnements
4. Annulation paiement
5. Modification rôle

## 4. Fixtures

### Users
```yaml
admin:
  email_address: admin@example.com
  role: admin
  
volunteer:
  email_address: volunteer@example.com
  role: volunteer
  
circus_member:
  email_address: circus@example.com
  role: circus_member
```

### SubscriptionTypes
```yaml
simple_membership:
  name: "Adhésion Simple"
  price: 1.0
  category: "simple"
  
circus_membership:
  name: "Adhésion Cirque"
  price: 10.0
  category: "circus"
```

### UserMemberships
```yaml
active_simple:
  user: member
  subscription_type: simple_membership
  status: "active"
  
active_circus:
  user: member
  subscription_type: circus_membership
  status: "active"
```

## 5. Points de Contrôle

### Sécurité
- Validation des permissions
- Protection contre les doublons
- Vérification des dates
- Contrôle des montants

### Intégrité
- Cohérence des statuts
- Historisation complète
- Traçabilité des modifications
- Validation des références

### Performance
- Optimisation des requêtes
- Gestion des transactions
- Indexation appropriée
- Cache efficace

## 6. Outils et Méthodes

### Tests Automatisés
- Minitest pour tests unitaires
- Fixtures pour données de test
- CI pour intégration continue
- Coverage pour couverture de code

### Validation de Données
- Validations ActiveRecord
- Validations personnalisées
- Callbacks
- Transactions

### Monitoring
- Logs d'erreurs
- Métriques de performance
- Alertes
- Rapports de test 
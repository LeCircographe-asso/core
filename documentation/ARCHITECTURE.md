# Le Circographe - Documentation Technique

## Introduction

Le Circographe est une application de gestion administrative pour une salle d'entraînement de cirque. Elle permet aux bénévoles et administrateurs de gérer les adhésions et abonnements, et aux visiteurs de créer un compte et gérer leur inscription à la newsletter.

### Objectif Principal
Faciliter la gestion quotidienne d'un espace d'entraînement de cirque en centralisant :
- La création et gestion des adhésions (sur place uniquement)
- L'enregistrement des présences aux entraînements
- Le suivi des paiements et la comptabilité
- Les statistiques de fréquentation
- La communication avec les membres via newsletter

### Public Cible
- **Administrateurs** : Gestion complète de l'espace et des membres
- **Bénévoles** : Gestion des présences et inscriptions sur place
- **Membres** : Consultation de leur profil, historique et gestion newsletter
- **Visiteurs** : Création de compte, inscription newsletter et consultation des informations publiques

### Fonctionnalités Clés
1. **Interface Publique**
   - Création de compte en ligne
   - Gestion de l'inscription newsletter
   - Consultation des informations

2. **Interface Administrative**
   - Création de comptes membres
   - Gestion des adhésions et abonnements
   - Enregistrement des paiements sur place
   - Suivi des présences
   - Gestion des newsletters

3. **Types d'Adhésions** (gérées par admin/bénévole)
   - Adhésion basique (1€/an)
   - Adhésion cirque (10€/an, 7€ tarif réduit)
   - Système de réductions (étudiants, RSA, handicap)

4. **Produits d'Accès** (vendus sur place)
   - Pass journée (4€)
   - Carnet 10 séances (30€)
   - Abonnements trimestriel (65€) et annuel (150€)

5. **Outils de Gestion**
   - Dashboard administratif temps réel
   - Statistiques de fréquentation
   - Gestion financière
   - Rapports automatisés

6. **Interface Membre**
   - Consultation du profil
   - Visualisation des droits d'accès
   - Historique personnel
   - Téléchargement des documents

## 1. Architecture Globale

### 1.1 Vue d'ensemble
```mermaid
graph TB
    subgraph Frontend
        Admin[Interface Admin]
        Member[Interface Membre]
        Assets[Assets/Webpack]
    end

    subgraph Backend
        Rails[Rails 8.0.1]
        Jobs[Background Jobs]
        Cache[Cache Layer]
    end

    subgraph Storage
        DB[(SQLite3)]
        Files[File Storage]
        GDrive[Google Drive]
    end

    Admin --> Rails
    Member --> Rails
    Rails --> DB
    Rails --> Files
    Jobs --> GDrive
    Jobs --> DB
    Cache --> DB
```

### 1.2 Flux de données
```mermaid
sequenceDiagram
    participant A as Admin/Bénévole
    participant F as Frontend
    participant B as Backend
    participant D as Database
    participant S as Storage

    A->>F: Action administrative
    F->>B: Requête AJAX/Turbo
    B->>D: Query
    D-->>B: Data
    B->>S: Store files
    S-->>B: Confirmation
    B-->>F: Response
    F-->>A: Update UI
```

### 1.1 Stack Technique
- **Backend**: Ruby on Rails 8.0.1
- **Frontend**: 
  - Hotwire (Turbo + Stimulus)
  - Progressive Web App (PWA)
  - React (future implementation)
- **Base de données**: SQLite3
- **Déploiement**: Ionos VPS
- **Intégrations futures**:
  - HelloAsso API (gestion événements)
  - API JSON pour React

### 1.2 Points Techniques Clés
- PWA pour expérience mobile
- Architecture API-first pour future intégration React
- Système de rôles avec héritage de permissions
- Gestion de sessions quotidiennes automatisée

## 2. Modèle de Données

### 2.1 Structure Actuelle
```mermaid
erDiagram
    User ||--o{ UserMembership : has
    UserMembership ||--o{ TrainingAttendee : enables
    SubscriptionType ||--o{ UserMembership : defines
    TrainingSession ||--o{ TrainingAttendee : records
```

### 2.2 Évolution Proposée
```mermaid
erDiagram
    User ||--o{ Membership : "est membre"
    User ||--o{ Subscription : "peut avoir"
    User ||--o{ TrainingAttendee : "participe"
    User ||--o{ Role : "a"
    Membership ||--o{ Payment : "génère"
    Subscription ||--o{ Payment : "génère"
    Subscription ||--o{ TrainingAttendee : "permet"
    TrainingSession ||--o{ TrainingAttendee : "enregistre"
    SubscriptionProduct ||--o{ Subscription : "définit"
    
    User {
        int id PK
        string email
        string encrypted_password
        string first_name
        string last_name
        string phone
        boolean active
        datetime created_at
        datetime updated_at
    }
    
    Role {
        int id PK
        int user_id FK
        string name
        datetime assigned_at
        datetime created_at
        datetime updated_at
    }
    
    Membership {
        int id PK
        int user_id FK
        string type
        boolean active
        datetime start_date
        datetime end_date
        decimal price_paid
        boolean reduced_price
        string reduction_type
        text reduction_justification
        datetime created_at
        datetime updated_at
    }
    
    Subscription {
        int id PK
        int user_id FK
        int product_id FK
        boolean active
        datetime start_date
        datetime end_date
        integer sessions_remaining
        decimal price_paid
        string status
        datetime created_at
        datetime updated_at
    }
    
    SubscriptionProduct {
        int id PK
        string name
        string type
        decimal price
        string duration_type
        integer duration_value
        boolean active
        datetime created_at
        datetime updated_at
    }
    
    TrainingSession {
        int id PK
        datetime date
        string status
        int max_capacity
        datetime created_at
        datetime updated_at
    }
    
    TrainingAttendee {
        int id PK
        int user_id FK
        int session_id FK
        int subscription_id FK
        boolean is_visitor
        datetime check_in_time
        int checked_by_id FK
        datetime created_at
        datetime updated_at
    }
    
    Payment {
        int id PK
        int user_id FK
        string payable_type
        int payable_id
        decimal amount
        string status
        string payment_method
        datetime paid_at
        datetime created_at
        datetime updated_at
    }
```

## 3. Logique Métier

### 3.1 Gestion des Membres

#### Statut de Membre
- **Adhésion Basique** (1€)
  - Donne accès aux événements
  - Permet d'être visiteur aux entraînements
  - Durée : 1 an

- **Adhésion Cirque** (10€/7€)
  - Inclut tous les avantages de l'adhésion basique
  - Permet l'achat d'abonnements pour la pratique
  - Tarif réduit possible (étudiant, RSA, handicap)
  - Durée : 1 an

#### Produits d'Accès à la Pratique
1. **Pass Journée** (4€)
   - Accès pour une journée
   - Nécessite une adhésion cirque valide

2. **Carnet 10 Séances** (30€)
   - 10 entrées
   - Validité : 6 mois
   - Nécessite une adhésion cirque valide

3. **Abonnement Trimestriel** (65€)
   - Accès illimité
   - Durée : 3 mois
   - Nécessite une adhésion cirque valide

4. **Abonnement Annuel** (150€)
   - Accès illimité
   - Durée : 1 an
   - Nécessite une adhésion cirque valide

### 3.2 Règles de Présence

#### Visiteurs
- Doit avoir une adhésion valide (basique ou cirque)
- Pas besoin d'abonnement
- Maximum 2 visites par an

#### Pratiquants
- Doit avoir une adhésion cirque valide
- Doit avoir un abonnement valide
- Le type d'abonnement détermine :
  - La durée d'accès (journée, trimestre, année)
  - Le nombre de séances (10 pour le carnet)

## 4. Flux de Données

### 4.1 Processus d'Adhésion
```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant F as Frontend
    participant M as MembershipController
    participant P as PaymentController
    participant D as Database

    U->>F: Demande d'adhésion
    F->>M: Crée adhésion
    
    alt Adhésion Cirque
        M->>M: Vérifie réduction
        M->>P: Calcule prix
    end
    
    M->>D: Enregistre adhésion (pending)
    P->>D: Crée paiement
    D-->>F: Confirmation
    
    alt Paiement OK
        P->>M: Valide paiement
        M->>D: Active adhésion
        D-->>F: Mise à jour statut
        F-->>U: Confirmation finale
    else Paiement KO
        P->>M: Échec paiement
        M->>D: Marque échec
        D-->>F: Erreur
        F-->>U: Message d'erreur
    end
```

### 4.2 Gestion des Présences
```mermaid
stateDiagram-v2
    [*] --> Ouverture: Création session
    Ouverture --> EnCours: Premier participant
    EnCours --> EnCours: Ajout participant
    EnCours --> Complète: Max capacité
    EnCours --> Fermée: Fin de journée
    Complète --> Fermée: Fin de journée
    Fermée --> [*]

    state EnCours {
        [*] --> CheckVisiteur: is_visitor
        CheckVisiteur --> ValidVisiteur: Adhésion OK
        CheckVisiteur --> RefusVisiteur: Pas d'adhésion
        
        [*] --> CheckPratiquant: !is_visitor
        CheckPratiquant --> CheckAdhesion: Vérifie adhésion
        CheckAdhesion --> CheckAbonnement: Adhésion OK
        CheckAbonnement --> ValidPratiquant: Abonnement OK
        CheckAbonnement --> RefusPratiquant: Abonnement KO
        CheckAdhesion --> RefusPratiquant: Adhésion KO
    }
```

## 5. Sécurité et Accès

### 5.1 Rôles Utilisateurs
- **Membre** : Accès lecture seule
- **Bénévole** : Gestion des présences
- **Admin** : Toutes les fonctionnalités
- **Super Admin** : Configuration système

### 5.2 Authentification
- Devise pour l'authentification
- JWT pour l'API
- Sessions sécurisées

## 6. Système de Rapports et Archivage

### 6.1 Rapports Hebdomadaires
- Génération : Lundi 3h
- Format : PDF
- Destinataires : Admins
- Contenu :
  - Statistiques de présence
  - Nouveaux membres
  - Abonnements expirés/à renouveler
  - Statistiques financières

### 6.2 Sauvegardes
- Base de données : Quotidienne (2h)
- Documents : Hebdomadaire
- Archives : Mensuelle
- Stockage : Local + Google Drive
- Rétention : 5 ans

## 7. Points d'Attention

### 7.1 Évolution Base de Données
- Séparation possible membres/abonnements
- Migration progressive
- Préserver l'historique
- Tests approfondis nécessaires

### 7.2 Performance
- Indexation des requêtes fréquentes
- Cache pour les données statiques
- Optimisation des requêtes de présence

### 7.3 Maintenance
- Monitoring des erreurs
- Alertes automatiques
- Documentation à jour

## 8. Workflows Critiques

### 8.1 Gestion des Adhésions
```ruby
workflow :adhesion do
  state :initial
  state :en_attente_paiement
  state :active
  state :expiree

  event :payer do
    transitions from: :initial, to: :active
  end

  event :expirer do
    transitions from: :active, to: :expiree
  end
end
```

### 8.2 Paiements en Trois Fois
```ruby
workflow :paiement_trois_fois do
  state :initial
  state :premier_paiement
  state :deuxieme_paiement
  state :complete
  state :en_defaut

  event :premier_versement do
    transitions from: :initial, to: :premier_paiement
  end

  event :deuxieme_versement do
    transitions from: :premier_paiement, to: :deuxieme_paiement
  end

  event :finaliser do
    transitions from: :deuxieme_paiement, to: :complete
  end
end
```

### 8.3 Processus de Paiement en Trois Fois
```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant F as Frontend
    participant P as PaymentController
    participant M as UserMembership
    participant S as SubscriptionType
    participant D as Database

    U->>F: Sélectionne paiement en 3x
    F->>P: Initie paiement
    P->>S: Vérifie éligibilité
    S-->>P: OK
    P->>M: Crée adhésion (statut: pending)
    
    loop 3 fois
        P->>D: Enregistre échéance
        D-->>P: OK
        P-->>F: Mise à jour statut
        F-->>U: Confirmation échéance
    end

    Note over P,M: Active après 1er paiement
    P->>M: Update statut: active
    M-->>F: Notification activation
    F-->>U: Accès autorisé
```

### 8.4 Architecture du Dashboard
```mermaid
graph TB
    subgraph Dashboard
        Nav[Navigation]
        Stats[Statistiques]
        Presence[Gestion Présence]
        Members[Gestion Membres]
    end

    subgraph Widgets
        W1[Widget Fréquentation]
        W2[Widget Financier]
        W3[Widget Adhésions]
        W4[Widget Activité]
    end

    subgraph Data
        D1[Stats temps réel]
        D2[Historique]
        D3[Rapports]
    end

    Nav --> Stats
    Nav --> Presence
    Nav --> Members
    
    Stats --> W1
    Stats --> W2
    Stats --> W3
    Stats --> W4

    W1 --> D1
    W2 --> D1
    W3 --> D2
    W4 --> D3
```

### 8.5 Déploiement
```mermaid
graph TB
    subgraph Client
        Browser[Navigateur]
        PWA[Progressive Web App]
    end

    subgraph "Serveur Production"
        Nginx[Nginx]
        Rails[Rails App]
        Sidekiq[Sidekiq Workers]
        Redis[Redis Cache]
        SQLite[SQLite DB]
    end

    subgraph "Services Externes"
        GDrive[Google Drive]
        Stripe[Stripe API]
        HelloAsso[HelloAsso API]
    end

    Browser --> Nginx
    PWA --> Nginx
    Nginx --> Rails
    Rails --> Redis
    Rails --> SQLite
    Sidekiq --> Redis
    Sidekiq --> SQLite
    Sidekiq --> GDrive
    Rails --> Stripe
    Rails --> HelloAsso
```

## 9. Sécurité et Permissions

### 9.1 Matrice des Droits
| Action                    | Guest | Member | Circus | Volunteer | Admin | Godmode |
|--------------------------|-------|---------|---------|-----------|--------|----------|
| Voir événements          | ✓     | ✓       | ✓       | ✓         | ✓      | ✓        |
| Gérer présences          | ✗     | ✗       | ✗       | ✓         | ✓      | ✓        |
| Gérer adhésions          | ✗     | ✗       | ✗       | ✓         | ✓      | ✓        |
| Voir statistiques        | ✗     | ✗       | ✗       | ✓         | ✓      | ✓        |
| Gérer admins             | ✗     | ✗       | ✗       | ✗         | ✗      | ✓        |

### 9.2 Validation des Actions
```ruby
def authorize_action(user, action)
  return false unless user.present?
  return true if user.godmode?
  
  case action
  when :manage_admins
    user.godmode?
  when :manage_members
    user.admin? || user.volunteer?
  when :view_statistics
    user.admin? || user.volunteer?
  else
    false
  end
end
```

## 10. Points d'Attention

### 10.1 Performance
- Optimisation des requêtes statistiques
- Cache pour données fréquemment accédées
- Indexation stratégique

### 10.2 Maintenance
- Sauvegarde quotidienne
- Monitoring des paiements
- Logs d'activité admin

### 10.3 Évolution
- Préparation API JSON
- Structure pour HelloAsso
- Migration future vers React

### 10.3 PWA et Mobile

#### 10.3.1 Fonctionnalités Hors-ligne
- **Consultation**
  - Profil utilisateur
  - Carte de membre
  - Historique personnel
  - Abonnements actifs
- **Mise en cache**
  - Dernières présences
  - Documents personnels
  - Planning des sessions

#### 10.3.2 Notifications Push
- **Configuration**
  - Préférences par utilisateur
  - Horaires programmés (12h par défaut)
  - Notifications urgentes (24/7)
  - Gestion des abonnements

- **Types**
  - **Administratives**
    - Rappels renouvellement
    - Confirmations paiement
    - Validations présence
    - Changements statut
  - **Informatives**
    - Changements horaires (opt-in admin)
    - Événements importants
    - Maintenance prévue
    - Actualités

- **Gestion**
  - Interface admin dédiée
  - Prévisualisation
  - Programmation
  - Historique d'envoi

#### 10.3.3 Sauvegardes et Sécurité
- **Sauvegardes**
  - Quotidiennes (BDD complète)
  - Hebdomadaires (système complet)
  - Mensuelles (archives)
  - Vérification automatique

- **Restauration**
  - Procédure documentée
  - Tests réguliers
  - Points de restauration
  - Migration assistée

- **Sécurité**
  - Chiffrement des données
  - Accès restreint
  - Audit des accès
  - Monitoring 24/7 

### 2.1 Modèle de données
```mermaid
erDiagram
    User ||--o{ UserRole : has
    User ||--o{ UserMembership : has
    User ||--o{ Payment : makes
    UserMembership ||--o{ TrainingAttendee : generates
    UserMembership ||--o{ UserMembershipSubscription : has
    SubscriptionType ||--o{ UserMembershipSubscription : defines
    Payment ||--o{ UserMembership : validates

    User {
        string email
        string password_digest
        datetime created_at
        boolean active
    }

    UserRole {
        int user_id
        string role_type
        datetime assigned_at
    }

    UserMembership {
        int user_id
        int subscription_type_id
        string status
        datetime start_date
        datetime end_date
        string reduction_type
    }

    SubscriptionType {
        string name
        decimal price
        decimal reduced_price
        string category
        boolean active
    }

    Payment {
        int user_id
        decimal amount
        string status
        string payment_method
    }
```

### 2.2 Workflow des adhésions
```mermaid
stateDiagram-v2
    [*] --> Initial
    Initial --> EnAttente: Création
    EnAttente --> Active: Paiement validé
    Active --> Expirée: Date fin
    Active --> Suspendue: Suspension
    Suspendue --> Active: Réactivation
    Expirée --> [*]
```

## 11. API REST

### 11.1 Points d'Entrée Principaux

#### Authentification et Compte
```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/refresh
```

#### Newsletter
```
POST   /api/v1/newsletter/subscribe
POST   /api/v1/newsletter/unsubscribe
GET    /api/v1/newsletter/status
```

#### Membres
```
GET    /api/v1/members
POST   /api/v1/members
GET    /api/v1/members/:id
PATCH  /api/v1/members/:id
DELETE /api/v1/members/:id
```

#### Adhésions
```
GET    /api/v1/memberships
POST   /api/v1/memberships
GET    /api/v1/memberships/:id
PATCH  /api/v1/memberships/:id
```

#### Abonnements
```
GET    /api/v1/subscriptions
POST   /api/v1/subscriptions
GET    /api/v1/subscriptions/:id
PATCH  /api/v1/subscriptions/:id
```

#### Présences
```
GET    /api/v1/training_sessions
POST   /api/v1/training_sessions
GET    /api/v1/training_sessions/:id/attendees
POST   /api/v1/training_sessions/:id/attendees
DELETE /api/v1/training_sessions/:id/attendees/:attendee_id
```

### 11.2 Format des Réponses

#### Succès
```json
{
  "status": "success",
  "data": {
    // données de la réponse
  },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100
  }
}
```

#### Erreur
```json
{
  "status": "error",
  "error": {
    "code": "INVALID_MEMBERSHIP",
    "message": "L'adhésion n'est pas valide",
    "details": {
      // détails supplémentaires
    }
  }
}
```

### 11.3 Sécurité API

#### Authentication
- JWT (JSON Web Tokens)
- Refresh Tokens
- CORS configuré pour les domaines autorisés

#### Rate Limiting
- 1000 requêtes/heure pour les clients authentifiés
- 60 requêtes/heure pour les clients non authentifiés
- Headers pour le suivi des limites

#### Versioning
- Version dans l'URL (/api/v1/...)
- Support des anciennes versions pendant 6 mois
- Documentation des changements breaking

### 11.4 Webhooks

#### Événements Disponibles
```
member.created
member.updated
membership.activated
membership.expired
subscription.created
subscription.renewed
payment.succeeded
payment.failed
training.registered
training.cancelled
```

#### Format des Webhooks
```json
{
  "event": "membership.activated",
  "timestamp": "2024-01-27T01:31:00Z",
  "data": {
    // données de l'événement
  }
}
``` 
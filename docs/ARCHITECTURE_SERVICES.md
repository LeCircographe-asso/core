# Architecture des Services - Le Circographe

**Date:** 2025-01-31  
**Status:** ✅ STABLE - Ne pas modifier sans validation  
**Dernière mise à jour:** 2025-01-31  
**Services:** 44 services (40 dans *Management, 4 non-standard)  
**Domaines:** 15 domaines *Management  
**Controllers:** 19 controllers admin (13 utilisent services, 6 sans logique métier complexe)

## Principe Fondamental

**Les controllers sont MINIMALISTES et délèguent TOUT vers les services.**

Les services suivent le pattern **Service Object avec ActiveModel::Model** :
- Validation des paramètres
- Délégation vers la logique métier dans les modèles (Person, etc.)
- Instrumentation pour audit (ActiveSupport::Notifications)
- Gestion d'erreurs standardisée

### Person (Entity) vs User (Account)

- **Person = Entity CRM** : fiche métier unique qui contient l'identité, l'historique financier (adhésions, cotisations, paiements) et tous les attributs d’usage.
- **User = Account** : accès web optionnel (email, mot de passe, rôle) qui délègue tous ses attributs de profil à `Person` via `delegate`.
- **Règles clés** :
  - Créer/éditer la fiche métier via `People::Register` / `People::PersonCreator` ; le compte web est créé via `People::UserAccountCreator` si besoin.
  - Supprimer un `User` ne détruit pas la `Person` (relation `has_one :user, dependent: :nullify`).
  - Supprimer une `Person` passe par `SoftDeletable` (`Person#archive!`) avec garde-fous financiers (`has_financial_data?`).
  - Toutes les opérations financières (`People::Payment*`, `People::Subscription*`, `People::Register`) travaillent **exclusivement** sur `Person`.

Cette séparation “Entity / Account” garantit :
- pas de perte d’historique quand un utilisateur supprime son compte web,
- la possibilité de gérer des personnes sans compte web (inscriptions papier, mineurs, bénévoles),
- une liaison safe quand un compte web est créé après coup ou par l’admin.

## Organisation par Domaine

### ✅ People::Membership* (Stable)
- `People::MembershipCreator` - Création d'adhésions
- `People::MembershipUpgrader` - Upgrade d'adhésions (Basic → Circus)
- `People::MembershipUpdater` - Mise à jour d'adhésion (type, dates)
- `People::MembershipDeactivator` - Désactivation d'adhésion (status: :inactive)

**Utilisé dans:** `Admin::MembershipsController` (create, update, destroy)

### ✅ People::Subscription* (Stable)
- `People::SubscriptionCreator` - Création de cotisations (2025-11)
- `People::SubscriptionUpgrader` - Upgrade/prorata (2025-11)

**Utilisé dans:** 
- `Admin::SubscriptionPlansController` (create)
- `Admin::SubscriptionsController` (upgrade)

### ✅ People::Payment* (Stable)
- `People::PaymentCreator` utilisé pour donations et paiements multi-lignes (2025-11)
- `People::PaymentUpdater` / `PaymentCanceller` / `PaymentRestorer` intégrés dans l’admin (2025-11)

**Utilisé dans:** 
- `Admin::PaymentsController` (create, update, destroy)
- `Admin::DonationsController` (create)
- `Admin::Users::PaymentsController` (create, update, destroy via `People::PaymentCreator` multi-lignes)

**Note:** Pour les donations, utiliser `item_type: "Donation"` et `item_id: person_id`. `People::PaymentCreator` ajoutera automatiquement une `PaymentLine` interne avec `item_type: "Payment"` et `item_id: payment.id` pour assurer la cohérence polymorphique. Pour les paiements multiples, fournir `payment_lines` au service ; la validation garantit que la somme des lignes = `total_cents`.

### ✅ People::AccountLinker (Support CRM)
- `People::AccountLinker` relie un compte web existant à une fiche CRM (`people.account_linked`)
- Utilisé par scripts de maintenance (`scripts/fix_person_user_merge.rb`)

### ⚠️ PersonManagement (Legacy ciblé)
- Ancien namespace conservé uniquement pour compatibilité. Les nouvelles fusions doivent passer par `People::AccountLinker` ou `People::AccountMerger`.

### ✅ UserManagement (Stable)
- `UserDeleter` - Suppression d'utilisateurs (Person)
- `UserUpdater` - Mise à jour User/Person (newsletter, rôles)

### ✅ EventManagement (Stable)
- `EventManagement::EventCreator` - Création d'événements
- `EventManagement::EventUpdater` - Mise à jour d'événements
- `EventManagement::EventDeleter` - Suppression d'événements

### ✅ AccountClaimManagement (Stable)
- `AccountClaimManagement::AccountClaimCreator` - Création de demandes de réclamation
- `AccountClaimManagement::AccountClaimConfirmer` - Confirmation et fusion de comptes

### ✅ AttendanceManagement (Stable)
- `AttendanceCreator` - Création de présences

**Utilisé dans:**
- `Admin::AttendancesController` (create)

### ✅ AttendanceListManagement (Stable)
- `AttendanceListCreator` - Création de listes de présence (avec gestion dates par défaut)
- `AttendanceListUpdater` - Mise à jour de listes de présence
- `AttendanceListDeleter` - Suppression de listes de présence

**Utilisé dans:**
- `Admin::AttendanceListsController` (create, update, destroy)

### ✅ MemberNumberManagement (Stable)
- `MemberNumberSuggester` - Suggestion de numéro d'adhérent
- `MemberNumberChanger` - Changement de numéro d'adhérent (avec validation format, unicité, historique)

**Utilisé dans:**
- `Admin::MemberNumbersController` (suggest, change)

### ✅ SubscriptionPlanManagement (Stable)
- `SubscriptionPlanUpdater` - Mise à jour de plan de cotisation (super_admin uniquement)
- `SubscriptionPlanDeleter` - Suppression de plan de cotisation (avec vérification book_of_entries)

**Utilisé dans:**
- `Admin::SubscriptionPlansController` (update, destroy)

### ✅ BlogManagement (Stable)
- `BlogManagement::BlogCreator` - Création de blogs
- `BlogManagement::BlogUpdater` - Mise à jour de blogs
- `BlogManagement::BlogDeleter` - Suppression de blogs

### ✅ MembershipTypeManagement (Stable)
- `MembershipTypeManagement::MembershipTypeCreator` - Création de types d'adhésion
- `MembershipTypeManagement::MembershipTypeUpdater` - Mise à jour de types d'adhésion
- `MembershipTypeManagement::MembershipTypeDeleter` - Suppression de types d'adhésion

### ✅ OpeningHoursManagement (Stable)
- `OpeningHoursManagement::OpeningHoursUpdater` - Mise à jour des horaires d'ouverture

### ✅ NewsletterManagement (Stable)
- `NewsletterManagement::NewsletterUpdater` - Mise à jour des abonnements newsletter

**Note:** L'inscription newsletter publique est gérée par `People::NewsletterSignup` (remplace le legacy `NewsletterSignupService`). La gestion authentifiée reste sous un updater newsletter (ex: `NewsletterManagement::NewsletterUpdater`).

### Autres Services (Non-standard, Legacy)

**Services non-standard (pas dans *Management):**
- `Admin::PaymentsService` - Helper service pour filtres et statistiques (utilisé dans `Admin::PaymentsController#index`)
- `Admin::DashboardStatisticsService` - Service pour calculer les statistiques du dashboard admin (utilisé dans `Admin::UsersController#index`)
- `MemberManagementService` - Service legacy pour génération numéros d'adhérent (utilisé par `MemberNumberManagement::*`)
- `People::NewsletterSignup` - Inscription newsletter publique (remplace `NewsletterSignupService`)
- `Web::UserRegistration` - Service pour inscription web (utilisé dans `RegistrationsController`)

**Note:** Ces services ne suivent pas le pattern DomainManagement standard mais sont acceptables car:
- Services helpers pour filtres/statistiques (Admin::PaymentsService, Admin::DashboardStatisticsService)
- Services legacy maintenus pour compatibilité
- Services web spécifiques (Web::UserRegistration)

## View Components

L'application utilise **ViewComponent** pour les composants réutilisables (21 composants actifs).

**Structure:**
- `app/components/admin/users/` - Composants admin users (badges, actions, display)
- `app/components/admin/payments/` - Composants payments (summary, display, actions)
- `app/components/ui/` - Composants UI réutilisables

**Bonnes pratiques:**
- Un composant = un fichier Ruby + un template ERB
- Namespace par domaine (Admin::Users::, Admin::Payments::)
- Logique de présentation uniquement (pas de logique métier)

**Voir:** `ARCHITECTURE_GUIDE.md` pour détails complets sur ViewComponents.

## Pattern Service Object

```ruby
module DomainManagement
  class ResourceCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :resource
    attribute :param_id, :integer
    attribute :recorded_by_id, :integer

    validates :resource, presence: true
    validates :param_id, presence: true
    validates :recorded_by_id, presence: true

    def call
      return failure("Invalid data") unless valid?

      begin
        # 1. Trouver les ressources
        param = Param.find(param_id)
        recorded_by = User.find(recorded_by_id)

        # 2. Déléguer vers la logique métier dans le modèle
        result = resource.create_something!(
          param,
          recorded_by: recorded_by
        )

        # 3. Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "something.created",
          resource_id: resource.id,
          param_id: param.id,
          recorded_by_id: recorded_by_id
        )

        success(result[:something], result[:payment])
      rescue ActiveRecord::RecordNotFound => e
        failure("Record not found: #{e.message}")
      rescue => e
        Rails.logger.error "[ResourceCreator] Error: #{e.message}"
        failure("Error: #{e.message}")
      end
    end

    private

    def success(resource, payment)
      OpenStruct.new(
        success?: true,
        resource: resource,
        payment: payment,
        message: "Resource created successfully"
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [message],
        message: message
      )
    end
  end
end
```

## Règles Importantes

1. **Les services NE font PAS de logique métier complexe** - Ils délèguent vers les modèles
2. **La logique métier reste dans les modèles** (Person#create_membership!, Person#create_subscription!, etc.)
3. **Les services ajoutent uniquement:**
   - Validation des paramètres
   - Instrumentation (audit)
   - Gestion d'erreurs standardisée
   - Interface cohérente pour les controllers

4. **NE PAS créer de services qui dupliquent la logique métier** - Toujours déléguer vers les modèles

## Controllers - Pattern Minimaliste

```ruby
def create
  creator = DomainManagement::ResourceCreator.new(
    resource: @resource,
    param_id: params[:param_id],
    recorded_by_id: Current.user.id
  )
  
  result = creator.call
  
  if result.success?
    redirect_to path, notice: "Success"
  else
    redirect_to path, alert: result.message
  end
end
```
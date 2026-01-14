class Person < ApplicationRecord
  # ===================================================================
  # ⚠️ DEPRECATED: newsletter_subscribed column
  # ===================================================================
  # This column is deprecated in favor of NewsletterSubscriber model.
  # The new table provides better tracking with source ('web', 'admin', 'import')
  # and supports orphaned emails (without Person).
  #
  # Migration plan:
  # 1. Phase 1 (current): Mark as deprecated, stop writing to it
  # 2. Phase 2: Migrate data from Person.newsletter_subscribed → NewsletterSubscriber
  # 3. Phase 3: Remove Person.newsletter_subscribed column
  #
  # TODO: Replace all newsletter_subscribed references with NewsletterSubscriber
  # ===================================================================

  # Relations (MODIFIER dependent pour protéger données financières)
  has_one :user, dependent: :nullify
  has_many :memberships, dependent: :restrict_with_error  # ✅ Empêcher suppression
  has_many :payments, dependent: :restrict_with_error     # ✅ Empêcher suppression
  has_many :attendances, dependent: :destroy
  has_many :book_of_entries, dependent: :destroy
  has_many :member_number_histories, dependent: :destroy
  has_one :newsletter_subscriber, dependent: :destroy  # ✅ NEW: Link to NewsletterSubscriber

  # Attribut pour skip validation dans certains cas (seeds, migrations)
  attr_accessor :skip_membership_validation

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, allow_blank: true
  validates :member_number, uniqueness: true, allow_blank: true

  # DEPRECATED: Use NewsletterSubscriber instead
  # Validation removed - handled by NewsletterSubscriber

  # Validation d'adhésion obligatoire (sauf cas spéciaux)
  # Une Person peut exister sans adhésion (inscription de base, newsletter, prospects, etc.)
  # L'adhésion sera ajoutée plus tard selon les besoins

  # Normalisation des données (via EmailNormalizable concern)

  # DEPRECATED: newsletter token generation removed (now handled by NewsletterSubscriber)

  # Méthodes
  def full_name
    "#{first_name} #{last_name}"
  end

  # Affiche le numéro d'adhérent de manière lisible
  def formatted_member_number
    return "Non assigné" unless member_number.present?

    parsed = MemberManagementService.parse_member_number(member_number)
    return member_number unless parsed

    "#{parsed[:year]} - #{parsed[:type]} - ##{parsed[:number]}"
  end

  # Retourne les détails du numéro d'adhérent
  def member_number_details
    return nil unless member_number.present?
    MemberManagementService.parse_member_number(member_number)
  end

  # Retourne l'historique des numéros d'adhérent
  def member_number_history
    member_number_histories.order(:assigned_at)
  end

  # Retourne le numéro d'adhérent actuel (depuis l'historique)
  def current_member_number_history
    member_number_histories.current.first
  end

  # Retourne tous les numéros d'adhérent précédents
  def previous_member_numbers
    member_number_histories.historical.order(:assigned_at)
  end

  # Change le numéro d'adhérent (avec historique)
  def change_member_number(new_membership_type, notes = nil)
    return false if member_number.blank?

    # Normaliser le type d'adhésion
    normalized_type = case new_membership_type.to_s.upcase
    when "CIRQUE", "C"
                       "Cirque"
    when "BASIQUE", "U", "BASIC"
                       "Basique"
    else
                       "Basique" # Par défaut
    end

    # Marquer l'ancien numéro comme remplacé
    current_history = current_member_number_history
    current_history&.mark_as_replaced!

    # Générer le nouveau numéro
    new_number = MemberManagementService.generate_member_number(new_membership_type)

    # Créer l'historique
    member_number_histories.create!(
      member_number: new_number,
      membership_type: normalized_type,
      year: Date.current.year,
      notes: notes,
      assigned_at: Time.current
    )

    # Mettre à jour le numéro actuel
    self.skip_membership_validation = true
    update!(member_number: new_number)

    new_number
  end

  def has_user_account?
    user.present?
  end

  def current_membership
    memberships.active.current.first
  end

  def has_active_membership?
    current_membership.present?
  end

  def can_buy_subscription_plans?
    # Seuls les membres Circus peuvent acheter des plans d'abonnement
    return false unless current_membership
    current_membership.membership_type.circus?
  end

  def minor?
    is_minor
  end

  def adult?
    !is_minor
  end

  # Scopes (active and archived are provided by SoftDeletable concern)
  scope :with_user_account, -> { joins(:user) }
  scope :without_user_account, -> { left_joins(:user).where(users: { id: nil }) }
  scope :by_name, ->(query) { where("first_name LIKE ? OR last_name LIKE ?",
                                        "%#{query}%", "%#{query}%") }
  scope :with_email, -> { where.not(email: [ nil, "" ]) }
  scope :with_phone, -> { where.not(phone: [ nil, "" ]) }
  scope :minors, -> { where(is_minor: true) }
  scope :adults, -> { where(is_minor: false) }

  # Scopes pour le tableau de bord admin
  scope :with_active_membership, -> { joins(:memberships).where(memberships: { status: :active }) }

  # Scope pour ne montrer que les Person "principales" (éviter les doublons)
  scope :main_people, -> {
    # Person avec User lié OU Person unique (pas de doublon de nom)
    where(
      id: Person.joins(:user).select(:id)
    ).or(
      where(
        id: Person.group(:first_name, :last_name)
                 .having("COUNT(*) = 1")
                 .select(:id)
      )
    )
  }

  scope :with_expiring_membership, -> {
    joins(:memberships)
      .where(memberships: { status: :active })
      .where("memberships.ended_at BETWEEN ? AND ?", Date.current, 30.days.from_now)
  }
  scope :with_expired_membership, -> {
    joins(:memberships)
      .where(memberships: { status: :expired })
  }
  scope :without_membership, -> { left_joins(:memberships).where(memberships: { id: nil }) }
  scope :search_by_contact, ->(query) {
    where("first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR phone LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
  }

  # Soft delete via SoftDeletable concern
  # Concerns
  include SoftDeletable
  include Humanizable
  include Dateable
  include EmailNormalizable

  # Vérifier si la personne a des données financières
  def has_financial_data?
    payments.exists? || memberships.where(status: :active).exists?
  end

  # Override archive! to add financial data check
  def archive!
    return false if has_financial_data?
    super # Call SoftDeletable's archive!
  end

  # Méthodes utilitaires pour la sécurité des fusions
  def safe_to_merge_with?(other_person)
    return false if other_person.nil?
    return false if id == other_person.id

    # Si les deux ont des Users différents, fusion dangereuse
    if user.present? && other_person.user.present? && user.id != other_person.user.id
      return false
    end

    true
  end

  def can_be_claimed_by?(email_to_check)
    return false if user.present? # Déjà lié à un User
    return false if email.blank? # Pas d'email
    return false if email.downcase != email_to_check.downcase # Email différent
    true
  end

  # Méthodes métier pour la création d'adhésions
  def create_membership!(membership_type, payment_method: :cash, recorded_by:, custom_amount_cents: nil, offer_reason: nil, donation_cents: nil)
    ActiveRecord::Base.transaction do
      # Vérifier les permissions pour les offres
      if payment_method.to_s == "offered"
        validate_offer_permissions!(recorded_by, "membership", offer_reason)
      end

      # Vérifier qu'il n'y a pas d'adhésion active
      if memberships.active.current.exists?
        raise "Cette personne a déjà une adhésion active"
      end

      # Créer l'adhésion
      membership = memberships.create!(
        membership_type: membership_type,
        started_at: Date.current,
        ended_at: Date.current + 1.year,
        status: :active
      )

      # Générer le numéro d'adhérent si la personne n'en a pas
      if member_number.blank?
        # Normaliser la catégorie pour la génération du numéro
        normalized_category = case membership_type.category
        when "circus"
          "CIRQUE"
        when "basic"
          "BASIQUE"
        else
          "BASIQUE"
        end

        MemberManagementService.assign_member_number(self, normalized_category) unless Rails.env.test?
      end

      # Déterminer le montant selon le mode de paiement
      amount_cents = calculate_amount_cents(payment_method, membership_type.price_cents, custom_amount_cents)
      donation_cents = donation_cents.to_i if donation_cents.present?
      donation_cents = nil if donation_cents.to_i <= 0
      total_cents = amount_cents + (donation_cents || 0)

      # Créer le paiement (toujours pour la traçabilité, même si montant = 0)
      description = generate_payment_description(payment_method, membership_type.name, "Membership")
      payment = payments.create!(
        total_cents: total_cents,
        payment_method: payment_method,
        status: :success,
        recorded_by: recorded_by,
        notes: "Paiement pour #{description}"
      )

      # Créer la ligne de paiement
      payment.payment_lines.create!(
        item_type: "Membership",
        item_id: membership.id,
        amount_cents: amount_cents,
        description: description
      )

      if donation_cents.present?
        payment.payment_lines.create!(
          item_type: "Payment",
          item_id: payment.id,
          amount_cents: donation_cents,
          description: "Donation"
        )
      end

      { membership: membership, payment: payment }
    end
  end

  # Méthodes métier pour la création de cotisations
  def create_subscription!(subscription_plan, payment_method: :cash, recorded_by:, record_attendance: false, custom_amount_cents: nil, offer_reason: nil, donation_cents: nil)
    ActiveRecord::Base.transaction do
      # Vérifier les permissions pour les offres
      if payment_method.to_s == "offered"
        validate_offer_permissions!(recorded_by, "subscription", offer_reason, subscription_plan)
      end

      # Vérifier que la personne peut acheter des plans d'abonnement
      unless can_buy_subscription_plans?
        raise "Cette personne doit avoir une adhésion Cirque pour acheter des plans d'abonnement"
      end

      # Déterminer les valeurs selon le type de plan
      sessions_remaining = case subscription_plan.duration
      when "pack10"
        subscription_plan.sessions_count || 10 # Par défaut 10 pour les packs
      when "day"
        1 # Une journée = 1 séance
      when "trimester", "annual"
        nil # Pas de limite de séances pour les abonnements (accès rapide à la présence)
      else
        subscription_plan.sessions_count || 1 # Par défaut 1 si non spécifié
      end

      expires_at = case subscription_plan.duration
      when "pack10"
        nil # Les packs10 n'expirent jamais et se réactivent avec une nouvelle adhésion
      when "day"
        Date.current.end_of_day # Expire à la fin de la journée achetée
      when "trimester"
        Date.current + 90.days
      when "annual"
        Date.current + 1.year
      else
        subscription_plan.validity_days ? Date.current + subscription_plan.validity_days.days : nil
      end

      # Créer le carnet d'entrées
      book_of_entry = book_of_entries.create!(
        subscription_plan: subscription_plan,
        sessions_remaining: sessions_remaining,
        status: :active,
        purchased_at: Time.current,
        expires_at: expires_at
      )

      # Déterminer le montant selon le mode de paiement
      amount_cents = calculate_amount_cents(payment_method, subscription_plan.price_cents, custom_amount_cents)
      donation_cents = donation_cents.to_i if donation_cents.present?
      donation_cents = nil if donation_cents.to_i <= 0
      total_cents = amount_cents + (donation_cents || 0)

      # Créer le paiement (toujours pour la traçabilité, même si montant = 0)
      description = generate_payment_description(payment_method, subscription_plan.name, "BookOfEntry")
      payment = payments.create!(
        total_cents: total_cents,
        payment_method: payment_method,
        status: :success,
        recorded_by: recorded_by,
        notes: "Paiement pour #{description}"
      )

      # Créer la ligne de paiement
      payment.payment_lines.create!(
        item_type: "BookOfEntry",
        item_id: book_of_entry.id,
        amount_cents: amount_cents,
        description: description
      )

      if donation_cents.present?
        payment.payment_lines.create!(
          item_type: "Payment",
          item_id: payment.id,
          amount_cents: donation_cents,
          description: "Donation"
        )
      end

      # Enregistrer la présence si demandé
      if record_attendance
        # Logique pour enregistrer la présence
        # À implémenter selon les besoins
      end

      { book_of_entry: book_of_entry, payment: payment }
    end
  end

  # Méthode métier pour les upgrades de cotisation avec prorata
  def upgrade_subscription!(from_book_id:, to_plan_id:, payment_method: :cash, recorded_by:)
    ActiveRecord::Base.transaction do
      # Vérifier adhésion Circus active
      raise "Adhésion Cirque active requise" unless can_buy_subscription_plans?

      from_book = book_of_entries.find(from_book_id)
      to_plan = SubscriptionPlan.find(to_plan_id)

      # Validation upgrades autorisés
      validate_subscription_upgrade!(from_book, to_plan)

      # Calculer crédit du plan actuel
      credit_cents = calculate_subscription_credit(from_book)

      # Suspendre ancien plan
      from_book.suspend!(reason: "Upgrade vers #{to_plan.name}")

      # Créer nouveau plan
      new_book_result = create_subscription!(to_plan, payment_method: payment_method, recorded_by: recorded_by)

      # Calculer montant à payer (prix nouveau - crédit ancien)
      amount_to_pay = [ to_plan.price_cents - credit_cents, 0 ].max

      # Créer paiement upgrade avec crédit
      payment = payments.create!(
        total_cents: amount_to_pay,
        payment_method: payment_method,
        status: :success,
        recorded_by: recorded_by,
        notes: "Upgrade cotisation: #{from_book.subscription_plan.name} → #{to_plan.name}. Crédit: #{credit_cents/100.0}€"
      )

      payment.payment_lines.create!(
        item_type: "BookOfEntry",
        item_id: new_book_result[:book_of_entry].id,
        amount_cents: amount_to_pay,
        description: "Upgrade avec crédit prorata"
      )

      {
        old_book: from_book,
        new_book: new_book_result[:book_of_entry],
        payment: payment,
        credit_applied: credit_cents
      }
    end
  end

  # Méthodes métier pour la création de donations
  def create_donation!(amount_cents, payment_method: :cash, recorded_by:, notes: "Donation")
    ActiveRecord::Base.transaction do
      # Créer le paiement
      payment = payments.create!(
        total_cents: amount_cents,
        payment_method: payment_method,
        status: :success,
        recorded_by: recorded_by,
        notes: notes
      )

      # Créer la ligne de paiement (utiliser Payment comme item_type pour cohérence avec PaymentCreator)
      payment.payment_lines.create!(
        item_type: "Payment",
        item_id: payment.id, # Lié au paiement lui-même pour les donations simples
        amount_cents: amount_cents,
        description: notes
      )

      payment
    end
  end

  # Méthode métier pour les upgrades d'adhésion
  def upgrade_membership!(new_membership_type, payment_method: :cash, recorded_by:, custom_amount_cents: nil, offer_reason: nil, donation_cents: nil)
    ActiveRecord::Base.transaction do
      # Vérifier qu'il y a une adhésion active
      current_membership = self.current_membership
      raise "Aucune adhésion active à upgrader" unless current_membership

      # Vérifier les permissions pour les offres
      if payment_method.to_s == "offered"
        validate_offer_permissions!(recorded_by, "membership_upgrade", offer_reason)
      end

      # Sauvegarder l'ancienne adhésion
      old_membership_type = current_membership.membership_type

      # CHANGEMENT: Plein tarif du nouveau type, pas de différence
      amount_to_pay = new_membership_type.price_cents

      # Effectuer l'upgrade
      new_membership = current_membership.upgrade_to!(new_membership_type)

      # Changer automatiquement le numéro d'adhérent si nécessaire
      old_member_number = member_number
      new_member_number = handle_member_number_change!(old_membership_type, new_membership_type, recorded_by)

      # Paiement plein tarif
      payment = create_payment_with_line!(
        amount_cents: amount_to_pay,
        payment_method: payment_method,
        recorded_by: recorded_by,
        item_type: "Membership",
        item_id: new_membership.id,
        description: "Upgrade d'adhésion de #{old_membership_type.name} vers #{new_membership_type.name} (plein tarif)",
        donation_cents: donation_cents
      )

      {
        membership: new_membership,
        payment: payment,
        member_number_changed: old_member_number != new_member_number,
        old_member_number: old_member_number,
        new_member_number: new_member_number
      }
    end
  end

  # Méthode métier pour les renouvellements d'adhésion
  def renew_membership!(membership_type, payment_method: :cash, recorded_by:, custom_amount_cents: nil, offer_reason: nil)
    ActiveRecord::Base.transaction do
      # Vérifier adhésion expirée
      current = self.current_membership
      if current&.active?
        raise "Adhésion encore active jusqu'au #{current.ended_at}. Renouvellement impossible."
      end

      # Marquer ancienne adhésion comme expired
      current&.update!(status: :expired) if current

      # Créer nouvelle adhésion
      result = create_membership!(membership_type, payment_method: payment_method, recorded_by: recorded_by, custom_amount_cents: custom_amount_cents, offer_reason: offer_reason)

      # NOUVEAU NUMÉRO D'ADHÉRENT À CHAQUE RENOUVELLEMENT
      old_number = member_number
      new_number = MemberManagementService.generate_member_number(get_membership_type_code(membership_type))

      # Historique changement
      create_member_number_change_history!(
        old_member_number: old_number,
        new_member_number: new_number,
        old_type: current ? get_membership_type_code(current.membership_type) : "AUCUN",
        new_type: get_membership_type_code(membership_type),
        recorded_by: recorded_by
      )

      update!(member_number: new_number)

      result.merge(
        renewed: true,
        old_member_number: old_number,
        new_member_number: new_number
      )
    end
  end

  private

  # Gérer le changement automatique de numéro d'adhérent lors d'un upgrade
  def handle_member_number_change!(old_membership_type, new_membership_type, recorded_by)
    # Déterminer si un changement de numéro est nécessaire
    old_type_code = get_membership_type_code(old_membership_type)
    new_type_code = get_membership_type_code(new_membership_type)

    # Si le type de numéro change, générer un nouveau numéro
    if old_type_code != new_type_code
      # Générer le nouveau numéro selon le type d'adhésion
      new_member_number = MemberManagementService.generate_member_number(new_type_code)

      # Créer l'historique du changement
      create_member_number_change_history!(old_member_number: member_number,
                                         new_member_number: new_member_number,
                                         old_type: old_type_code,
                                         new_type: new_type_code,
                                         recorded_by: recorded_by)

      # Mettre à jour le numéro actuel
      update!(member_number: new_member_number)

      new_member_number
    else
      # Pas de changement nécessaire, retourner le numéro actuel
      member_number
    end
  end

  # Obtenir le code de type d'adhésion pour la génération de numéro
  def get_membership_type_code(membership_type)
    case membership_type.category
    when "circus"
      "CIRQUE"
    when "basic"
      "BASIQUE"
    else
      "BASIQUE" # Par défaut
    end
  end

  # Obtenir le nom de type d'adhésion pour l'historique
  def get_membership_type_name(membership_type)
    case membership_type.category
    when "circus"
      "Cirque"
    when "basic"
      "Basique"
    else
      "Basique" # Par défaut
    end
  end

  # Créer l'historique du changement de numéro d'adhérent
  def create_member_number_change_history!(old_member_number:, new_member_number:, old_type:, new_type:, recorded_by:)
    # Marquer l'ancien numéro comme remplacé
    if old_member_number.present?
      old_history = member_number_histories.where(member_number: old_member_number, replaced_at: nil).first
      old_history&.mark_as_replaced!
    end

    # Convertir les codes en noms pour l'historique
    old_type_name = old_type == "CIRQUE" ? "Cirque" : "Basique"
    new_type_name = new_type == "CIRQUE" ? "Cirque" : "Basique"

    # Créer l'historique pour le nouveau numéro
    member_number_histories.create!(
      member_number: new_member_number,
      membership_type: new_type_name,
      year: Date.current.year,
      notes: "Changement automatique lors de l'upgrade d'adhésion (#{old_type_name} → #{new_type_name}) - Enregistré par #{recorded_by.email}",
      assigned_at: Time.current
    )
  end

  # Calculer le montant selon le mode de paiement
  def calculate_amount_cents(payment_method, base_price_cents, custom_amount_cents = nil)
    case payment_method.to_s
    when "offered"
      custom_amount_cents || 0
    else
      base_price_cents
    end
  end

  # Générer la description d'un paiement
  def generate_payment_description(payment_method, item_name, item_type)
    case payment_method.to_s
    when "offered"
      case item_type
      when "Membership" then "Adhésion offerte #{item_name}"
      when "BookOfEntry" then "Cotisation offerte #{item_name}"
      when "MembershipUpgrade" then "Upgrade offert d'adhésion vers #{item_name}"
      else "#{item_type} offert #{item_name}"
      end
    else
      case item_type
      when "Membership" then "Adhésion #{item_name}"
      when "BookOfEntry" then "Plan d'abonnement #{item_name}"
      when "MembershipUpgrade" then "Upgrade d'adhésion vers #{item_name}"
      else "#{item_type} #{item_name}"
      end
    end
  end


  # Validation des permissions pour les offres
  def validate_offer_permissions!(recorded_by, offer_type, offer_reason, subscription_plan = nil)
    # Vérifier que l'utilisateur a les permissions
    unless recorded_by.super_admin? || recorded_by.admin? || recorded_by.volunteer?
      raise "Seuls les bénévoles, admins et super-admins peuvent offrir des #{offer_type}s"
    end

    # Vérifier que la raison est fournie
    if offer_reason.blank?
      raise "Une raison doit être fournie pour offrir une #{offer_type}"
    end

    # Restrictions spécifiques pour les bénévoles
    if recorded_by.volunteer?
      if offer_type == "subscription" && subscription_plan&.duration != "day"
        raise "Les bénévoles ne peuvent offrir que des cotisations 'journée'"
      end
    end

    # Enregistrer l'audit trail
    create_offer_audit_log!(recorded_by, offer_type, offer_reason, subscription_plan)
  end

  # Créer un log d'audit pour les offres
  def create_offer_audit_log!(recorded_by, offer_type, offer_reason, subscription_plan = nil)
    Rails.logger.info "OFFER AUDIT: #{recorded_by.email} offered #{offer_type} to #{full_name} (#{id}) - Reason: #{offer_reason}"
  end

  # Méthode utilitaire pour créer un paiement avec sa ligne
  def create_payment_with_line!(amount_cents:, payment_method:, recorded_by:, item_type:, item_id:, description:, donation_cents: nil)
    donation_cents = donation_cents.to_i if donation_cents.present?
    donation_cents = nil if donation_cents.to_i <= 0
    total_cents = amount_cents + (donation_cents || 0)

    payment = payments.create!(
      total_cents: total_cents,
      payment_method: payment_method,
      status: :success,
      recorded_by: recorded_by,
      notes: description
    )

    payment.payment_lines.create!(
      item_type: item_type,
      item_id: item_id,
      amount_cents: amount_cents,
      description: description
    )

    if donation_cents.present?
      payment.payment_lines.create!(
        item_type: "Payment",
        item_id: payment.id,
        amount_cents: donation_cents,
        description: "Donation"
      )
    end

    payment
  end

  # Validation des upgrades de cotisations autorisés
  def validate_subscription_upgrade!(from_book, to_plan)
    from_duration = from_book.subscription_plan.duration
    to_duration = to_plan.duration

    # Pack10 → Trimestre/Année OK
    # Trimestre → Année OK
    # Day interdit
    valid_upgrades = {
      "pack10" => [ "trimester", "annual" ],
      "trimester" => [ "annual" ]
    }

    allowed = valid_upgrades[from_duration]
    raise "Upgrade #{from_duration} → #{to_duration} non autorisé" unless allowed&.include?(to_duration)
  end

  # Calculer le crédit prorata pour upgrade cotisation
  def calculate_subscription_credit(book_of_entry)
    plan = book_of_entry.subscription_plan

    case plan.duration
    when "pack10"
      # Pas de crédit, suspension seulement (selon 11.c)
      0
    when "trimester"
      # Prorata temporel (jours restants)
      total_days = 90
      days_remaining = ((book_of_entry.expires_at.to_date - Date.current).to_i)
      (plan.price_cents * days_remaining / total_days.to_f).round
    when "annual"
      # Prorata temporel (jours restants)
      total_days = 365
      days_remaining = ((book_of_entry.expires_at.to_date - Date.current).to_i)
      (plan.price_cents * days_remaining / total_days.to_f).round
    else
      0
    end
  end

  # Méthodes pour les statistiques et la traçabilité
  def offered_payments_count
    payments.where(payment_method: "offered").count
  end

  def offered_payments_total
    payments.where(payment_method: "offered").sum(:total_cents)
  end

  def free_offers_count
    payments.where(payment_method: "offered", total_cents: 0).count
  end

  def paid_offers_count
    payments.where(payment_method: "offered").where("total_cents > 0").count
  end

  def membership_upgrades_count
    payments.joins(:payment_lines)
            .where(payment_lines: { item_type: "MembershipUpgrade" })
            .count
  end

  def subscription_purchases_count
    payments.joins(:payment_lines)
            .where(payment_lines: { item_type: "BookOfEntry" })
            .count
  end

  # Méthodes de classe pour les statistiques globales
  def self.total_offered_payments
    joins(:payments).where(payments: { payment_method: "offered" }).count
  end

  def self.total_free_offers
    joins(:payments).where(payments: { payment_method: "offered", total_cents: 0 }).count
  end

  def self.total_paid_offers
    joins(:payments).where(payments: { payment_method: "offered" }).where("payments.total_cents > 0").count
  end

  def self.offered_payments_by_reason
    joins(:payments)
      .where(payments: { payment_method: "offered" })
      .group("payments.notes")
      .count
  end

  def self.upgrades_today
    joins(:payments)
      .joins("JOIN payment_lines ON payments.id = payment_lines.payment_id")
      .where(payment_lines: { item_type: "MembershipUpgrade" })
      .where(payments: { created_at: Date.current.beginning_of_day..Date.current.end_of_day })
      .count
  end

  # normalize_email maintenant dans EmailNormalizable concern

  def must_have_active_membership
    return if new_record? # Skip à la création
    return if memberships.active.any?
    return if skip_membership_validation # Skip si explicitement demandé

    errors.add(:base, "Une adhésion active est obligatoire")
  end

  # Read-only helper to check newsletter status from NewsletterSubscriber
  def newsletter_subscribed?
    return false unless email.present?

    subscriber = NewsletterSubscriber.find_by(email: email)
    subscriber&.subscribed? || false
  end

  # Make newsletter_subscribed? public (AR makes bool methods private)
  public :newsletter_subscribed?
end

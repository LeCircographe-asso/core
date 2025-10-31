class Person < ApplicationRecord
  # Relations (MODIFIER dependent pour protéger données financières)
  has_one :user, dependent: :nullify
  has_many :memberships, dependent: :restrict_with_error  # ✅ Empêcher suppression
  has_many :payments, dependent: :restrict_with_error     # ✅ Empêcher suppression
  has_many :attendances, dependent: :destroy
  has_many :book_of_entries, dependent: :destroy
  has_many :member_number_histories, dependent: :destroy

  # Attribut pour skip validation dans certains cas (seeds, migrations)
  attr_accessor :skip_membership_validation

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, allow_blank: true
  validates :member_number, uniqueness: true, allow_blank: true

  # Validation conditionnelle : email obligatoire si newsletter activée
  validates :email, presence: true, if: :newsletter_subscribed?

  # Validation d'adhésion obligatoire (sauf cas spéciaux)
  # Une Person peut exister sans adhésion (inscription de base, newsletter, prospects, etc.)
  # L'adhésion sera ajoutée plus tard selon les besoins

  # Normalisation des données
  before_validation :normalize_email

  # Callbacks newsletter
  before_create :generate_newsletter_token, if: :newsletter_subscribed?
  before_update :generate_newsletter_token, if: -> {
    newsletter_subscribed? && newsletter_unsubscribe_token.blank?
  }

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

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :archived, -> { where.not(deleted_at: nil) }
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

  # Vérifier si la personne a des données financières
  def has_financial_data?
    payments.exists? || memberships.where(status: :active).exists?
  end

  # Soft delete
  def archive!
    return false if has_financial_data?
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def archived?
    deleted_at.present?
  end

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :archived, -> { where.not(deleted_at: nil) }
  scope :with_user_account, -> { joins(:user) }
  scope :without_user_account, -> { left_joins(:user).where(users: { id: nil }) }
  scope :by_name, ->(query) { where("first_name LIKE ? OR last_name LIKE ?",
                                        "%#{query}%", "%#{query}%") }
  scope :with_email, -> { where.not(email: [ nil, "" ]) }
  scope :with_phone, -> { where.not(phone: [ nil, "" ]) }
  scope :minors, -> { where(is_minor: true) }
  scope :adults, -> { where(is_minor: false) }

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
  def create_membership!(membership_type, payment_method: :cash, recorded_by:, custom_amount_cents: nil, offer_reason: nil)
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
        when 'circus'
          'CIRQUE'
        when 'basic'
          'BASIQUE'
        else
          'BASIQUE'
        end
        
        MemberManagementService.assign_member_number(self, normalized_category)
      end

      # Déterminer le montant selon le mode de paiement
      amount_cents = calculate_amount_cents(payment_method, membership_type.price_cents, custom_amount_cents)

      # Créer le paiement (toujours pour la traçabilité, même si montant = 0)
      description = generate_payment_description(payment_method, membership_type.name, "Membership")
      payment = payments.create!(
        total_cents: amount_cents,
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

      { membership: membership, payment: payment }
    end
  end

  # Méthodes métier pour la création de cotisations
  def create_subscription!(subscription_plan, payment_method: :cash, recorded_by:, record_attendance: false, custom_amount_cents: nil, offer_reason: nil)
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

      # Créer le paiement (toujours pour la traçabilité, même si montant = 0)
      description = generate_payment_description(payment_method, subscription_plan.name, "BookOfEntry")
      payment = payments.create!(
        total_cents: amount_cents,
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

      # Enregistrer la présence si demandé
      if record_attendance
        # Logique pour enregistrer la présence
        # À implémenter selon les besoins
      end

      { book_of_entry: book_of_entry, payment: payment }
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

      # Créer la ligne de paiement
      payment.payment_lines.create!(
        item_type: "Donation",
        item_id: payment.id, # Lié au paiement lui-même pour les donations simples
        amount_cents: amount_cents,
        description: notes
      )

      payment
    end
  end

  # Méthode métier pour les upgrades d'adhésion
  def upgrade_membership!(new_membership_type, payment_method: :cash, recorded_by:, custom_amount_cents: nil, offer_reason: nil)
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
      
      # Calculer la différence de prix
      price_difference = new_membership_type.price_cents - old_membership_type.price_cents

      # Effectuer l'upgrade
      new_membership = current_membership.upgrade_to!(new_membership_type)

      # Changer automatiquement le numéro d'adhérent si nécessaire
      old_member_number = member_number
      new_member_number = handle_member_number_change!(old_membership_type, new_membership_type, recorded_by)

      # Gérer le paiement selon le type
      payment = case payment_method.to_s
      when "offered"
        handle_offered_upgrade_payment!(price_difference, custom_amount_cents, recorded_by, old_membership_type, new_membership_type, new_membership)
      else
        handle_standard_upgrade_payment!(price_difference, payment_method, recorded_by, old_membership_type, new_membership_type, new_membership)
      end

      { 
        membership: new_membership, 
        payment: payment,
        member_number_changed: old_member_number != new_member_number,
        old_member_number: old_member_number,
        new_member_number: new_member_number
      }
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
    when 'circus'
      'CIRQUE'
    when 'basic'
      'BASIQUE'
    else
      'BASIQUE' # Par défaut
    end
  end

  # Obtenir le nom de type d'adhésion pour l'historique
  def get_membership_type_name(membership_type)
    case membership_type.category
    when 'circus'
      'Cirque'
    when 'basic'
      'Basique'
    else
      'Basique' # Par défaut
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
    old_type_name = old_type == 'CIRQUE' ? 'Cirque' : 'Basique'
    new_type_name = new_type == 'CIRQUE' ? 'Cirque' : 'Basique'

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

  # Gérer le paiement d'un upgrade offert
  def handle_offered_upgrade_payment!(price_difference, custom_amount_cents, recorded_by, old_membership_type, new_membership_type, new_membership)
    amount = calculate_amount_cents("offered", 0, custom_amount_cents)
    
    # Toujours créer un paiement pour la traçabilité, même si montant = 0
    create_payment_with_line!(
      amount_cents: amount,
      payment_method: "offered",
      recorded_by: recorded_by,
      item_type: "Membership",
      item_id: new_membership.id,
      description: "Upgrade offert d'adhésion de #{old_membership_type.name} vers #{new_membership_type.name} - Montant: #{(amount / 100.0).round(2)}€"
    )
  end

  # Gérer le paiement d'un upgrade standard
  def handle_standard_upgrade_payment!(price_difference, payment_method, recorded_by, old_membership_type, new_membership_type, new_membership)
    if price_difference > 0
      # Paiement de la différence
      create_payment_with_line!(
        amount_cents: price_difference,
        payment_method: payment_method,
        recorded_by: recorded_by,
        item_type: "Membership",
        item_id: new_membership.id,
        description: "Upgrade d'adhésion de #{old_membership_type.name} vers #{new_membership_type.name}"
      )
    elsif price_difference < 0
      # Crédit/remboursement
      create_payment_with_line!(
        amount_cents: price_difference.abs,
        payment_method: "refund",
        recorded_by: recorded_by,
        item_type: "Membership",
        item_id: new_membership.id,
        description: "Crédit pour upgrade d'adhésion de #{old_membership_type.name} vers #{new_membership_type.name}"
      )
    else
      nil # Pas de différence de prix
    end
  end

  # Méthode utilitaire pour créer un paiement avec sa ligne
  def create_payment_with_line!(amount_cents:, payment_method:, recorded_by:, item_type:, item_id:, description:)
    payment = payments.create!(
      total_cents: amount_cents,
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

    payment
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

  def normalize_email
    self.email = nil if email.blank?
  end

  def must_have_active_membership
    return if new_record? # Skip à la création
    return if memberships.active.any?
    return if skip_membership_validation # Skip si explicitement demandé

    errors.add(:base, "Une adhésion active est obligatoire")
  end


  def generate_newsletter_token
    self.newsletter_unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end
end

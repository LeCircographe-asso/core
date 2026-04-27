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

  has_one :user, dependent: :nullify
  has_many :memberships, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error
  has_many :attendances, dependent: :destroy
  has_many :contributions, dependent: :destroy
  has_many :member_number_histories, dependent: :destroy
  has_one :newsletter_subscriber, dependent: :destroy

  attr_accessor :skip_membership_validation

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, allow_blank: true
  validates :member_number, uniqueness: true, allow_blank: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def formatted_member_number
    return "Non assigné" unless member_number.present?

    parsed = MemberManagementService.parse_member_number(member_number)
    return member_number unless parsed

    "#{parsed[:year]} - #{parsed[:type]} - ##{parsed[:number]}"
  end

  def member_number_details
    return nil unless member_number.present?
    MemberManagementService.parse_member_number(member_number)
  end

  def member_number_history
    member_number_histories.order(:assigned_at)
  end

  def current_member_number_history
    member_number_histories.current.first
  end

  def previous_member_numbers
    member_number_histories.historical.order(:assigned_at)
  end

  def change_member_number(new_membership_type, notes = nil)
    return false if member_number.blank?

    normalized_type = case new_membership_type.to_s.upcase
    when "CIRQUE", "C"
                       "Cirque"
    when "BASIQUE", "U", "BASIC"
                       "Basique"
    else
                       "Basique"
    end

    current_history = current_member_number_history
    current_history&.mark_as_replaced!

    new_number = MemberManagementService.generate_member_number(new_membership_type)

    member_number_histories.create!(
      member_number: new_number,
      membership_type: normalized_type,
      year: Date.current.year,
      notes: notes,
      assigned_at: Time.current
    )

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

  def can_buy_contribution_formulas?
    return false unless current_membership
    current_membership.membership_type.circus?
  end

  def minor?
    is_minor
  end

  def adult?
    !is_minor
  end

  scope :with_user_account, -> { joins(:user) }
  scope :without_user_account, -> { left_joins(:user).where(users: { id: nil }) }
  scope :by_name, ->(query) { where("first_name LIKE ? OR last_name LIKE ?",
                                        "%#{query}%", "%#{query}%") }
  scope :with_email, -> { where.not(email: [ nil, "" ]) }
  scope :with_phone, -> { where.not(phone: [ nil, "" ]) }
  scope :minors, -> { where(is_minor: true) }
  scope :adults, -> { where(is_minor: false) }

  scope :with_active_membership, -> { joins(:memberships).where(memberships: { status: :active }) }

  scope :main_people, -> {
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

  include SoftDeletable
  include Humanizable
  include Dateable
  include EmailNormalizable

  def has_financial_data?
    payments.exists? || memberships.where(status: :active).exists?
  end

  def archive!
    return false if has_financial_data?
    super
  end

  def safe_to_merge_with?(other_person)
    return false if other_person.nil?
    return false if id == other_person.id

    if user.present? && other_person.user.present? && user.id != other_person.user.id
      return false
    end

    true
  end

  def can_be_claimed_by?(email_to_check)
    return false if user.present?
    return false if email.blank?
    return false if email.downcase != email_to_check.downcase
    true
  end

  def create_membership!(membership_type, payment_method: :cash, recorded_by:, custom_amount_cents: nil, offer_reason: nil, donation_cents: nil)
    ActiveRecord::Base.transaction do
      if payment_method.to_s == "offered"
        validate_offer_permissions!(recorded_by, "membership", offer_reason)
      end

      if memberships.active.current.exists?
        raise "Cette personne a déjà une adhésion active"
      end

      membership = memberships.create!(
        membership_type: membership_type,
        started_at: Date.current,
        ended_at: Date.current + 1.year,
        status: :active
      )

      if member_number.blank?
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

      amount_cents = calculate_amount_cents(payment_method, membership_type.price_cents, custom_amount_cents)
      donation_cents = donation_cents.to_i if donation_cents.present?
      donation_cents = nil if donation_cents.to_i <= 0
      total_cents = amount_cents + (donation_cents || 0)

      description = generate_payment_description(payment_method, membership_type.name, "Membership")
      payment = payments.create!(
        total_cents: total_cents,
        payment_method: payment_method,
        status: :success,
        recorded_by: recorded_by,
        notes: "Paiement pour #{description}"
      )

      payment.payment_lines.create!(
        item_type: "Membership",
        item_id: membership.id,
        amount_cents: amount_cents,
        description: description
      )

      if donation_cents.present?
        payment.payment_lines.create!(
          item_type: "Donation",
          item_id: payment.id,
          amount_cents: donation_cents,
          description: "Donation"
        )
      end

      { membership: membership, payment: payment }
    end
  end

  def create_contribution!(contribution_formula, payment_method: :cash, recorded_by:, record_attendance: false, custom_amount_cents: nil, offer_reason: nil, donation_cents: nil)
    ActiveRecord::Base.transaction do
      if payment_method.to_s == "offered"
        validate_offer_permissions!(recorded_by, "contribution", offer_reason, contribution_formula)
      end

      unless can_buy_contribution_formulas?
        raise "Cette personne doit avoir une adhésion Cirque active pour acheter une cotisation"
      end

      sessions_remaining = case contribution_formula.duration
      when "pack10"
        contribution_formula.sessions_count || 10
      when "day"
        1
      when "trimester", "annual"
        nil
      else
        contribution_formula.sessions_count || 1
      end

      expires_at = case contribution_formula.duration
      when "pack10"
        nil
      when "day"
        Date.current.end_of_day
      when "trimester"
        Date.current + 90.days
      when "annual"
        Date.current + 1.year
      else
        contribution_formula.validity_days ? Date.current + contribution_formula.validity_days.days : nil
      end

      contribution = contributions.create!(
        contribution_formula: contribution_formula,
        sessions_remaining: sessions_remaining,
        status: :active,
        purchased_at: Time.current,
        expires_at: expires_at
      )

      amount_cents = calculate_amount_cents(payment_method, contribution_formula.price_cents, custom_amount_cents)
      donation_cents = donation_cents.to_i if donation_cents.present?
      donation_cents = nil if donation_cents.to_i <= 0
      total_cents = amount_cents + (donation_cents || 0)

      description = generate_payment_description(payment_method, contribution_formula.name, "BookOfEntry")
      payment = payments.create!(
        total_cents: total_cents,
        payment_method: payment_method,
        status: :success,
        recorded_by: recorded_by,
        notes: "Paiement pour #{description}"
      )

      payment.payment_lines.create!(
        item_type: "BookOfEntry",
        item_id: contribution.id,
        amount_cents: amount_cents,
        description: description
      )

      if donation_cents.present?
        payment.payment_lines.create!(
          item_type: "Donation",
          item_id: payment.id,
          amount_cents: donation_cents,
          description: "Donation"
        )
      end

      if record_attendance
        # Logique de présence — implémentation à compléter selon les besoins.
      end

      { contribution: contribution, payment: payment }
    end
  end

  def upgrade_contribution!(from_contribution_id:, to_formula_id:, payment_method: :cash, recorded_by:)
    ActiveRecord::Base.transaction do
      raise "Adhésion Cirque active requise" unless can_buy_contribution_formulas?

      from_contribution = contributions.find(from_contribution_id)
      to_formula = ContributionFormula.find(to_formula_id)

      validate_contribution_upgrade!(from_contribution, to_formula)

      credit_cents = calculate_contribution_credit(from_contribution)

      from_contribution.suspend!(reason: "Upgrade vers #{to_formula.name}")

      new_result = create_contribution!(to_formula, payment_method: payment_method, recorded_by: recorded_by)

      amount_to_pay = [ to_formula.price_cents - credit_cents, 0 ].max

      payment = payments.create!(
        total_cents: amount_to_pay,
        payment_method: payment_method,
        status: :success,
        recorded_by: recorded_by,
        notes: "Upgrade cotisation: #{from_contribution.contribution_formula.name} → #{to_formula.name}. Crédit: #{credit_cents/100.0}€"
      )

      payment.payment_lines.create!(
        item_type: "BookOfEntry",
        item_id: new_result[:contribution].id,
        amount_cents: amount_to_pay,
        description: "Upgrade avec crédit prorata"
      )

      {
        old_contribution: from_contribution,
        new_contribution: new_result[:contribution],
        payment: payment,
        credit_applied: credit_cents
      }
    end
  end

  def create_donation!(amount_cents, payment_method: :cash, recorded_by:, notes: "Donation")
    ActiveRecord::Base.transaction do
      payment = payments.create!(
        total_cents: amount_cents,
        payment_method: payment_method,
        status: :success,
        recorded_by: recorded_by,
        notes: notes
      )

      payment.payment_lines.create!(
        item_type: "Donation",
        item_id: payment.id,
        amount_cents: amount_cents,
        description: notes
      )

      payment
    end
  end

  def upgrade_membership!(new_membership_type, payment_method: :cash, recorded_by:, custom_amount_cents: nil, offer_reason: nil, donation_cents: nil)
    ActiveRecord::Base.transaction do
      current_membership = self.current_membership
      raise "Aucune adhésion active à upgrader" unless current_membership

      if payment_method.to_s == "offered"
        validate_offer_permissions!(recorded_by, "membership_upgrade", offer_reason)
      end

      old_membership_type = current_membership.membership_type

      amount_to_pay = new_membership_type.price_cents

      new_membership = current_membership.upgrade_to!(new_membership_type)

      old_member_number = member_number
      new_member_number = handle_member_number_change!(old_membership_type, new_membership_type, recorded_by)

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

  def renew_membership!(membership_type, payment_method: :cash, recorded_by:, custom_amount_cents: nil, offer_reason: nil)
    ActiveRecord::Base.transaction do
      current = self.current_membership
      if current&.active?
        raise "Adhésion encore active jusqu'au #{current.ended_at}. Renouvellement impossible."
      end

      current&.update!(status: :expired) if current

      result = create_membership!(membership_type, payment_method: payment_method, recorded_by: recorded_by, custom_amount_cents: custom_amount_cents, offer_reason: offer_reason)

      old_number = member_number
      new_number = MemberManagementService.generate_member_number(get_membership_type_code(membership_type))

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

  def handle_member_number_change!(old_membership_type, new_membership_type, recorded_by)
    old_type_code = get_membership_type_code(old_membership_type)
    new_type_code = get_membership_type_code(new_membership_type)

    if old_type_code != new_type_code
      new_member_number = MemberManagementService.generate_member_number(new_type_code)

      create_member_number_change_history!(old_member_number: member_number,
                                         new_member_number: new_member_number,
                                         old_type: old_type_code,
                                         new_type: new_type_code,
                                         recorded_by: recorded_by)

      update!(member_number: new_member_number)

      new_member_number
    else
      member_number
    end
  end

  def get_membership_type_code(membership_type)
    case membership_type.category
    when "circus"
      "CIRQUE"
    when "basic"
      "BASIQUE"
    else
      "BASIQUE"
    end
  end

  def get_membership_type_name(membership_type)
    case membership_type.category
    when "circus"
      "Cirque"
    when "basic"
      "Basique"
    else
      "Basique"
    end
  end

  def create_member_number_change_history!(old_member_number:, new_member_number:, old_type:, new_type:, recorded_by:)
    if old_member_number.present?
      old_history = member_number_histories.where(member_number: old_member_number, replaced_at: nil).first
      old_history&.mark_as_replaced!
    end

    old_type_name = old_type == "CIRQUE" ? "Cirque" : "Basique"
    new_type_name = new_type == "CIRQUE" ? "Cirque" : "Basique"

    member_number_histories.create!(
      member_number: new_member_number,
      membership_type: new_type_name,
      year: Date.current.year,
      notes: "Changement automatique lors de l'upgrade d'adhésion (#{old_type_name} → #{new_type_name}) - Enregistré par #{recorded_by.email}",
      assigned_at: Time.current
    )
  end

  def calculate_amount_cents(payment_method, base_price_cents, custom_amount_cents = nil)
    case payment_method.to_s
    when "offered"
      custom_amount_cents || 0
    else
      base_price_cents
    end
  end

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

  def validate_offer_permissions!(recorded_by, offer_type, offer_reason, contribution_formula = nil)
    unless recorded_by.super_admin? || recorded_by.admin? || recorded_by.volunteer?
      raise "Seuls les bénévoles, admins et super-admins peuvent offrir des #{offer_type}s"
    end

    if offer_reason.blank?
      raise "Une raison doit être fournie pour offrir une #{offer_type}"
    end

    if recorded_by.volunteer?
      if offer_type == "contribution" && contribution_formula&.duration != "day"
        raise "Les bénévoles ne peuvent offrir que des cotisations 'journée'"
      end
    end

    create_offer_audit_log!(recorded_by, offer_type, offer_reason, contribution_formula)
  end

  def create_offer_audit_log!(recorded_by, offer_type, offer_reason, contribution_formula = nil)
    Rails.logger.info "OFFER AUDIT: #{recorded_by.email} offered #{offer_type} to #{full_name} (#{id}) - Reason: #{offer_reason}"
  end

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
        item_type: "Donation",
        item_id: payment.id,
        amount_cents: donation_cents,
        description: "Donation"
      )
    end

    payment
  end

  def validate_contribution_upgrade!(from_contribution, to_formula)
    from_duration = from_contribution.contribution_formula.duration
    to_duration = to_formula.duration

    valid_upgrades = {
      "pack10" => [ "trimester", "annual" ],
      "trimester" => [ "annual" ]
    }

    allowed = valid_upgrades[from_duration]
    raise "Upgrade #{from_duration} → #{to_duration} non autorisé" unless allowed&.include?(to_duration)
  end

  def calculate_contribution_credit(contribution)
    formula = contribution.contribution_formula

    case formula.duration
    when "pack10"
      0
    when "trimester"
      total_days = 90
      days_remaining = ((contribution.expires_at.to_date - Date.current).to_i)
      (formula.price_cents * days_remaining / total_days.to_f).round
    when "annual"
      total_days = 365
      days_remaining = ((contribution.expires_at.to_date - Date.current).to_i)
      (formula.price_cents * days_remaining / total_days.to_f).round
    else
      0
    end
  end

  public

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

  def contribution_purchases_count
    payments.joins(:payment_lines)
            .where(payment_lines: { item_type: "BookOfEntry" })
            .count
  end

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

  def must_have_active_membership
    return if new_record?
    return if memberships.active.any?
    return if skip_membership_validation

    errors.add(:base, "Une adhésion active est obligatoire")
  end

  def newsletter_subscribed?
    return false unless email.present?

    subscriber = NewsletterSubscriber.find_by(email: email)
    subscriber&.subscribed? || false
  end

  public :newsletter_subscribed?
end

# frozen_string_literal: true

class Person < ApplicationRecord
  include PersonPaymentReporting
  include BroadcastsDashboardStats

  after_create_commit :broadcast_dashboard_stats

  REDUCED_RATE_REASONS = [
    "RSA",
    "Mineur",
    "Situation Handicap",
    "Étudiant",
    "Autre"
  ].freeze

  has_one :user, dependent: :restrict_with_error
  has_many :account_claims, dependent: :restrict_with_error
  has_many :memberships, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error
  has_many :attendances, dependent: :destroy
  has_many :contributions, dependent: :destroy
  has_many :member_number_histories, dependent: :destroy
  has_one :newsletter_subscriber, dependent: :destroy

  attr_accessor :skip_membership_validation

  before_save :compute_minor_status

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, allow_blank: true
  validates :member_number, uniqueness: true, allow_blank: true
  validate :email_not_used_by_other_user_account
  validate :reduced_rate_consistency

  def full_name
    "#{first_name} #{last_name}"
  end

  def formatted_member_number
    return "Non assigné" if member_number.blank?

    parsed = MemberManagementService.parse_member_number(member_number)
    return member_number unless parsed

    "#{parsed[:year]} - #{parsed[:type]} - ##{parsed[:number]}"
  end

  def member_number_details
    return nil if member_number.blank?

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

  # Dernière adhésion la plus récente par date de fin (profil : distinguer « jamais adhéré » / « adhésion terminée »).
  def most_recent_membership
    memberships.order(ended_at: :desc, started_at: :desc).first
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

  def allows_rate_kind?(rate_kind)
    allowed_rate_kinds.include?(rate_kind.to_s.presence || "standard")
  end

  def allowed_rate_kinds
    kinds = [ "standard" ]
    kinds << "reduced" if reduced_rate_eligible?
    kinds
  end

  scope :with_user_account, -> { joins(:user) }
  scope :without_user_account, -> { where.missing(:user) }
  scope :by_name, lambda { |query|
    where("first_name LIKE ? OR last_name LIKE ?",
          "%#{query}%", "%#{query}%")
  }
  scope :with_email, -> { where.not(email: [ nil, "" ]) }
  scope :with_phone, -> { where.not(phone: [ nil, "" ]) }
  scope :minors, -> { where(is_minor: true) }
  scope :adults, -> { where(is_minor: false) }

  scope :with_active_membership, -> { joins(:memberships).where(memberships: { status: :active }) }

  scope :main_people, lambda {
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

  scope :with_expiring_membership, lambda {
    joins(:memberships)
      .where(memberships: { status: :active })
      .where("memberships.ended_at BETWEEN ? AND ?", Date.current, 30.days.from_now)
  }
  scope :with_expired_membership, lambda {
    joins(:memberships)
      .where(memberships: { status: :expired })
  }
  scope :without_membership, -> { where.missing(:memberships) }
  scope :search_by_contact, lambda { |query|
    where("first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR phone LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
  }

  include SoftDeletable
  include Humanizable
  include Dateable
  include EmailNormalizable

  def has_financial_data?
    payments.exists? || memberships.exists?(status: :active)
  end

  def archive!
    return false if has_financial_data?

    super
  end

  def safe_to_merge_with?(other_person)
    return false if other_person.nil?
    return false if id == other_person.id

    return false if user.present? && other_person.user.present? && user.id != other_person.user.id

    true
  end

  def can_be_claimed_by?(email_to_check)
    return false if user.present?
    return false if email.blank?
    return false if email.downcase != email_to_check.downcase

    true
  end

  def renew_membership!(membership_type, recorded_by:, payment_method: :cash, custom_amount_cents: nil, offer_reason: nil)
    ActiveRecord::Base.transaction do
      current = current_membership
      raise "Adhésion encore active jusqu'au #{current.ended_at}. Renouvellement impossible." if current&.active?

      current&.update!(status: :expired)

      creation_result = People::MembershipCreator.new(
        person: self,
        membership_type_id: membership_type.id,
        payment_method: payment_method.to_s,
        recorded_by_id: recorded_by.id,
        custom_amount_cents: custom_amount_cents,
        offer_reason: offer_reason
      ).call

      raise "Cette personne a déjà une adhésion active" if creation_result.success? && creation_result.already_existed
      raise creation_result.message unless creation_result.success?

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

      {
        membership: creation_result.membership,
        payment: creation_result.payment,
        renewed: true,
        old_member_number: old_number,
        new_member_number: new_number
      }
    end
  end

  private

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

  def must_have_active_membership
    return if new_record?
    return if memberships.active.any?
    return if skip_membership_validation

    errors.add(:base, "Une adhésion active est obligatoire")
  end

  private

  # NOTE: is_minor and the associated reduced rate are recomputed on each save.
  # If a person turns 18 between two saves, the flag won't auto-update until
  # the record is next written. Consider a nightly job if real-time accuracy matters.
  def compute_minor_status
    return unless birth_date.present?

    self.is_minor = birth_date > 18.years.ago.to_date
    sync_reduced_rate_for_minor
  end

  def sync_reduced_rate_for_minor
    if is_minor
      self.reduced_rate_eligible = true
      self.reduced_rate_reason = "Mineur"
      self.reduced_rate_proof = nil
    elsif reduced_rate_reason == "Mineur"
      # Person just became an adult — clear the minor-specific reduced rate.
      self.reduced_rate_eligible = false
      self.reduced_rate_reason = nil
    end
  end

  def email_not_used_by_other_user_account
    return if email.blank?
    return unless Identity::EmailPolicy.person_email_conflicts_with_other_user?(email: email, current_person_id: id)

    errors.add(:email, "est deja utilisee par un autre compte utilisateur")
  end

  def reduced_rate_consistency
    return unless reduced_rate_eligible?

    if reduced_rate_reason.blank?
      errors.add(:reduced_rate_reason, "doit être renseigné pour un tarif réduit")
      return
    end

    unless REDUCED_RATE_REASONS.include?(reduced_rate_reason)
      errors.add(:reduced_rate_reason, "n'est pas une raison de tarif réduit valide")
    end

    return unless reduced_rate_reason == "Autre" && reduced_rate_proof.blank?

    errors.add(:reduced_rate_proof, "doit être renseigné quand la raison de tarif réduit est Autre")
  end
end

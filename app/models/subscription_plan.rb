class SubscriptionPlan < ApplicationRecord
  # Relations
  belongs_to :membership_type
  has_many :book_of_entries, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :duration, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :sessions_count, numericality: { greater_than: 0 }, if: :is_pack?
  validates :validity_days, numericality: { greater_than: 0 }, if: :is_pack?

  # Enum pour les durées selon le domain_model_circographe.md
  enum :duration, {
    day: 0,
    trimester: 1,
    annual: 2,
    pack10: 3
  }

  # Méthodes
  def for_circus_members?
    # Seuls les membres Circus peuvent acheter des plans d'abonnement
    membership_type.circus?
  end

  def is_pack?
    duration == "pack10"
  end

  def price_euros
    price_cents / 100.0
  end

  def price_euros=(value)
    self.price_cents = (value.to_f * 100).round
  end

  def duration_days
    case duration
    when "day"
      1
    when "trimester"
      90
    when "annual"
      365
    when "pack10"
      validity_days || 365 # Par défaut 1 an si pas spécifié
    else
      0
    end
  end

  def sessions_available
    is_pack? ? sessions_count : nil
  end

  # Scopes
  scope :for_circus_members, -> { joins(:membership_type).where(membership_types: { category: [ :circus_full, :circus_reduced ] }) }
  scope :day_plans, -> { where(duration: :day) }
  scope :trimester_plans, -> { where(duration: :trimester) }
  scope :annual_plans, -> { where(duration: :annual) }
  scope :pack_plans, -> { where(duration: :pack10) }
  scope :by_price, -> { order(:price_cents) }

  # Méthodes de classe pour créer les plans par défaut
  def self.create_default_plans!
    # Plans pour membres Circus
    circus_types = MembershipType.circus_types

    circus_types.each do |membership_type|
      # Plan journée
      find_or_create_by(name: "Journée - #{membership_type.name}") do |sp|
        sp.membership_type = membership_type
        sp.duration = :day
        sp.price_cents = 800 # 8€
        sp.description = "Accès aux cours pour une journée"
      end

      # Plan trimestre
      find_or_create_by(name: "Trimestre - #{membership_type.name}") do |sp|
        sp.membership_type = membership_type
        sp.duration = :trimester
        sp.price_cents = 6000 # 60€
        sp.description = "Accès aux cours pendant 3 mois"
      end

      # Plan annuel
      find_or_create_by(name: "Annuel - #{membership_type.name}") do |sp|
        sp.membership_type = membership_type
        sp.duration = :annual
        sp.price_cents = 20000 # 200€
        sp.description = "Accès aux cours pendant 1 an"
      end

      # Pack 10 séances
      find_or_create_by(name: "Pack 10 séances - #{membership_type.name}") do |sp|
        sp.membership_type = membership_type
        sp.duration = :pack10
        sp.price_cents = 7000 # 70€
        sp.sessions_count = 10
        sp.validity_days = 365
        sp.description = "10 séances valables 1 an"
      end
    end
  end
end

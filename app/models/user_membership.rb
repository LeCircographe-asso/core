class UserMembership < ApplicationRecord
  belongs_to :user
  belongs_to :subscription_type
  belongs_to :payment, optional: true

  # has_many :payments, dependent: :destroy
  has_many :training_attendees
  has_many :user_membership_subscriptions
  has_many :subscription_types, through: :user_membership_subscriptions


  validates :user_id, :subscription_type_id, presence: true

  scope :active, -> { 
    where("expiration_date >= ? AND status = ?", Date.current, true)
  }

  def valid_subscription?
    return false unless expiration_date >= Date.today
    return false unless status
    
    case subscription_type.name
    when 'daily'
      # Expire à la fin de la journée
      created_at.to_date == Date.today
    when 'booklet'
      remaining_entries.positive? && !expired?
    else # trimestrial ou annual
      !expired?
    end
  end

  def remaining_entries
    return nil unless subscription_type.name == 'booklet'
    10 - training_attendees.count
  end

  def expired?
    expiration_date < Date.today
  end

  def can_be_upgraded_to?(new_subscription_type)
    return false if expired?
    return false unless status
    
    case subscription_type.name
    when 'daily'
      true # peut toujours upgrader depuis daily
    when 'trimestrial'
      new_subscription_type.name == 'annual'
    else
      false # annual et booklet ne peuvent pas être upgradés
    end
  end

  def subscription_details
    case subscription_type.name
    when 'daily'
      "Journée (expire ce soir)"
    when 'booklet'
      "Carnet (#{remaining_entries} passages restants)"
    when 'trimestrial'
      "Abonnement trimestriel"
    when 'annual'
      "Abonnement annuel"
    end
  end

  # Gérer la conversion d'un abonnement
  def convert_to!(new_subscription_type, payment_params)
    return false unless can_be_converted_to?(new_subscription_type)

    transaction do
      # Marquer l'ancien abonnement comme inactif
      update!(status: false)

      # Créer le nouveau paiement
      payment = user.payments.create!(payment_params)

      # Créer le nouvel abonnement
      user.user_memberships.create!(
        subscription_type: new_subscription_type,
        payment: payment,
        status: true,
        expiration_date: calculate_expiration_date(new_subscription_type)
      )
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def booklet?
    subscription_type.name == 'booklet'
  end

  def decrement_entries_count
    return unless booklet?
    # ... reste du code ...
  end

  private

  def can_be_converted_to?(new_type)
    case subscription_type.name
    when 'daily'
      # Depuis une journée, on peut tout prendre
      true
    when 'booklet'
      # Depuis un carnet, seulement si presque vide
      remaining_entries <= 2 && 
        ['trimestrial', 'annual'].include?(new_type.name)
    when 'trimestrial'
      # Depuis un trimestre, seulement vers annuel
      new_type.name == 'annual'
    else
      false
    end
  end

  def calculate_expiration_date(subscription_type)
    case subscription_type.name
    when 'daily'
      Date.today.end_of_day
    when 'booklet'
      1.year.from_now
    else
      Date.today + subscription_type.duration.days
    end
  end
end

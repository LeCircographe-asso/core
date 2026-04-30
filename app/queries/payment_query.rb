# frozen_string_literal: true

module PaymentQuery
  def self.by_person(person_id)
    Payment.where(person_id: person_id)
  end

  def self.by_user(user_id)
    user = User.find(user_id)
    user.person ? Payment.where(person_id: user.person.id) : Payment.none
  end

  def self.by_status(status)
    Payment.where(status: status)
  end

  def self.by_date_range(start_date, end_date)
    Payment.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
  end

  def self.successful
    Payment.where(status: :success)
  end

  def self.with_person_and_recorded_by
    Payment.includes(:person, :recorded_by, :payment_lines)
  end

  def self.ordered_by_date(direction = :desc)
    Payment.order(created_at: direction)
  end

  def self.ordered_by_created_at(direction = :desc)
    Payment.order(created_at: direction)
  end

  def self.total_amount
    successful.sum(:total_cents)
  end

  def self.total_donation
    Payment.joins(:payment_lines)
           .where(status: :success)
           .where(payment_lines: { item_type: 'Donation' })
           .sum('payment_lines.amount_cents')
  end
end

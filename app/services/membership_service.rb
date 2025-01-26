class MembershipService
  def self.register_base_membership(user:, payment_method:, recorded_by:, donation_amount: 0)
    payment = Payment.create!(
      user: user,
      amount: 1, # 1€ pour l'adhésion simple
      payment_method: payment_method,
      status: 'completed',
      recorded_by: recorded_by,
      donation_amount: donation_amount
    )

    UserMembership.create!(
      user: user,
      subscription_type: SubscriptionType.find_by(category: 'membership'),
      payment: payment,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: 'active'
    )
  end

  def self.register_circus_membership(user:, payment_method:, recorded_by:, donation_amount: 0)
    payment = Payment.create!(
      user: user,
      amount: 10, # 10€ pour l'adhésion cirque
      payment_method: payment_method,
      status: 'completed',
      recorded_by: recorded_by,
      donation_amount: donation_amount
    )

    UserMembership.create!(
      user: user,
      subscription_type: SubscriptionType.find_by(category: 'circus_membership'),
      payment: payment,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: 'active'
    )
  end

  def self.register_training_subscription(user:, subscription_type:, payment_method:, recorded_by:, donation_amount: 0)
    unless user.user_memberships.active.joins(:subscription_type)
              .where(subscription_types: { category: 'circus_membership' }).exists?
      raise "L'utilisateur doit avoir une adhésion cirque valide"
    end

    payment = Payment.create!(
      user: user,
      amount: subscription_type.price,
      payment_method: payment_method,
      status: 'completed',
      recorded_by: recorded_by,
      donation_amount: donation_amount
    )

    membership = UserMembership.new(
      user: user,
      subscription_type: subscription_type,
      payment: payment,
      start_date: Date.current,
      status: 'active'
    )

    case subscription_type.category
    when 'ten_pass'
      membership.remaining_sessions = 10
    when 'trimester'
      membership.end_date = 3.months.from_now.to_date
    when 'annual'
      membership.end_date = 1.year.from_now.to_date
    end

    membership.save!
    membership
  end
end 
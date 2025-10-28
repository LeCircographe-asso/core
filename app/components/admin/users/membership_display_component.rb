class Admin::Users::MembershipDisplayComponent < ViewComponent::Base
  def initialize(person:)
    @person = person
  end

  private

  attr_reader :person

  def current_membership
    @current_membership ||= person.current_membership
  end

  def has_active_membership?
    current_membership.present?
  end

  def membership_type_name
    current_membership&.membership_type&.name
  end

  def membership_price
    current_membership&.membership_type&.price_euros
  end

  def membership_start_date
    current_membership&.started_at&.strftime("%d/%m/%Y")
  end

  def membership_end_date
    current_membership&.ended_at&.strftime("%d/%m/%Y")
  end

  def is_circus_member?
    current_membership&.membership_type&.circus?
  end

  def can_purchase_subscriptions?
    is_circus_member?
  end

  def subscription_plans
    @subscription_plans ||= SubscriptionPlan.for_circus_members
  end
end

require "test_helper"

class SubscriptionTypeTest < ActiveSupport::TestCase
  def setup
    @simple_membership = subscription_types(:basic_membership)
    @circus_membership = subscription_types(:circus_membership)
    @day_pass = subscription_types(:day_pass)
    @ten_pass = subscription_types(:ten_sessions)
  end

  test "validations de base" do
    subscription = SubscriptionType.new(
      name: "Test",
      category: :membership,
      price: 1
    )
    assert subscription.valid?
  end

  test "le prix ne peut pas être négatif" do
    subscription = SubscriptionType.new(
      name: "Test",
      category: :membership,
      price: -1
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:price], "doit être supérieur ou égal à 0"
  end

  test "le nom doit être unique" do
    duplicate = SubscriptionType.new(
      name: "Adhésion Simple",
      category: :membership,
      price: 1
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "n'est pas disponible"
  end

  test "scopes de filtrage" do
    assert_includes SubscriptionType.memberships, @simple_membership
    assert_includes SubscriptionType.memberships, @circus_membership
    assert_not_includes SubscriptionType.memberships, @day_pass
    
    assert_includes SubscriptionType.training_passes, @day_pass
    assert_not_includes SubscriptionType.training_passes, @simple_membership
  end

  test "requires_circus_membership?" do
    assert_not @simple_membership.requires_circus_membership?
    assert_not @circus_membership.requires_circus_membership?
    assert @day_pass.requires_circus_membership?
    assert @ten_pass.requires_circus_membership?
  end

  test "has_expiration?" do
    assert @day_pass.has_expiration?
    assert_not @ten_pass.has_expiration?
  end

  test "duration_in_days" do
    assert_equal 1, @day_pass.duration_in_days
    assert_nil @ten_pass.duration_in_days
  end

  test "adhésion simple valide" do
    subscription = SubscriptionType.new(
      name: "Nouvelle Adhésion Simple",
      category: :membership,
      price: 1,
      active: true
    )
    
    assert subscription.valid?
  end

  test "adhésion cirque valide" do
    subscription = SubscriptionType.new(
      name: "Nouvelle Adhésion Cirque",
      category: :circus_membership,
      price: 10,
      active: true
    )
    
    assert subscription.valid?
  end

  test "ne peut pas créer une adhésion simple avec un prix différent de 1€" do
    subscription = SubscriptionType.new(
      name: "Test Adhésion Simple",
      category: :membership,
      price: 5,
      active: true
    )
    
    assert_not subscription.valid?
    assert_includes subscription.errors[:price], "doit être de 1€ pour l'adhésion simple"
  end

  test "ne peut pas créer une adhésion cirque avec un prix différent de 10€" do
    subscription = SubscriptionType.new(
      name: "Test Adhésion Cirque",
      category: :circus_membership,
      price: 15,
      active: true
    )
    
    assert_not subscription.valid?
    assert_includes subscription.errors[:price], "doit être de 10€ pour l'adhésion cirque"
  end

  test "vérifie si un abonnement nécessite une adhésion cirque" do
    day_pass = SubscriptionType.new(category: :day_pass)
    ten_pass = SubscriptionType.new(category: :ten_pass)
    trimester = SubscriptionType.new(category: :trimester)
    annual = SubscriptionType.new(category: :annual)
    membership = SubscriptionType.new(category: :membership)
    
    assert day_pass.requires_circus_membership?
    assert ten_pass.requires_circus_membership?
    assert trimester.requires_circus_membership?
    assert annual.requires_circus_membership?
    assert_not membership.requires_circus_membership?
  end

  test "vérifie si un abonnement a des sessions limitées" do
    ten_pass = SubscriptionType.new(category: :ten_pass)
    trimester = SubscriptionType.new(category: :trimester)
    
    assert ten_pass.has_limited_sessions?
    assert_not trimester.has_limited_sessions?
  end

  test "vérifie si un abonnement a une date d'expiration" do
    ten_pass = SubscriptionType.new(category: :ten_pass)
    trimester = SubscriptionType.new(category: :trimester)
    annual = SubscriptionType.new(category: :annual)
    
    assert_not ten_pass.has_expiration_date?
    assert trimester.has_expiration_date?
    assert annual.has_expiration_date?
  end

  test "scope memberships retourne uniquement les adhésions" do
    memberships = SubscriptionType.memberships
    assert_includes memberships, @simple_membership
    assert_includes memberships, @circus_membership
    assert_not_includes memberships, @day_pass
  end

  test "scope training_passes retourne uniquement les abonnements d'entraînement" do
    passes = SubscriptionType.training_passes
    assert_includes passes, @day_pass
    assert_includes passes, @ten_pass
    assert_not_includes passes, @circus_membership
  end

  test "scope available_for_purchase exclut les adhésions" do
    available = SubscriptionType.available_for_purchase
    assert_includes available, @day_pass
    assert_not_includes available, @simple_membership
  end

  test "validation des prix spécifiques" do
    subscription = SubscriptionType.new(
      name: "Test Simple",
      category: :membership,
      price: 2
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:price], "doit être de 1€ pour l'adhésion simple"
  end

  def validate_subscription_prices
    case category
    when 'day_pass'
      errors.add(:price, "doit être de 4€") unless price == 4
    when 'ten_pass'
      errors.add(:price, "doit être de 30€") unless price == 30
    when 'trimester'
      errors.add(:price, "doit être de 65€") unless price == 65
    when 'annual'
      errors.add(:price, "doit être de 150€") unless price == 150
    end
  end

  def validate_no_active_subscription_with_day_pass
    if user_membership.subscription_type.day_pass?
      active_sub = user.user_memberships.active.joins(:subscription_type)
                      .where(subscription_types: { category: ['trimester', 'annual'] })
                      .exists?
      if active_sub
        errors.add(:base, "Un abonnement actif existe déjà")
      end
    end
  end
end

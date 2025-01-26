require "test_helper"

class UserMembershipTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "test@example.com",
      first_name: "Test",
      last_name: "User",
      password: "password",
      password_confirmation: "password"
    )
    
    @simple_membership = SubscriptionType.create!(
      name: "Adhésion Simple",
      category: 0,  # basic_membership
      price: 1,
      duration_type: "year",
      duration_value: 1,
      has_limited_sessions: false,
      active: true,
      valid_from: Date.current,
      year_reference: Date.current.year
    )
    
    @circus_membership = SubscriptionType.create!(
      name: "Adhésion Cirque",
      category: 1,  # circus_membership
      price: 10,
      duration_type: "year",
      duration_value: 1,
      has_limited_sessions: false,
      active: true,
      valid_from: Date.current,
      year_reference: Date.current.year
    )
  end

  test "création d'une adhésion simple valide" do
    membership = UserMembership.new(
      user: @user,
      subscription_type: @simple_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )
    
    assert membership.valid?
  end

  test "ne peut pas créer d'adhésion sans utilisateur" do
    membership = UserMembership.new(
      subscription_type: @simple_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )
    
    assert_not membership.valid?
    assert_includes membership.errors[:user_id], "doit être rempli(e)"
  end

  test "ne peut pas avoir deux adhésions actives du même type" do
    # Première adhésion
    UserMembership.create!(
      user: @user,
      subscription_type: @simple_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )

    # Deuxième adhésion du même type
    duplicate = UserMembership.new(
      user: @user,
      subscription_type: @simple_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "Un abonnement actif de ce type existe déjà"
  end

  test "peut avoir une adhésion simple et une adhésion cirque en même temps" do
    # Adhésion simple
    simple = UserMembership.create!(
      user: @user,
      subscription_type: @simple_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )

    # Adhésion cirque
    circus = UserMembership.new(
      user: @user,
      subscription_type: @circus_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )

    assert circus.valid?
  end

  test "la date de fin doit être après la date de début" do
    membership = UserMembership.new(
      user: @user,
      subscription_type: @simple_membership,
      start_date: Date.current,
      end_date: 1.day.ago.to_date,
      status: :active
    )

    assert_not membership.valid?
    assert_includes membership.errors[:end_date], "doit être après la date de début"
  end

  test "scope active retourne uniquement les adhésions valides" do
    # Adhésion active
    active = UserMembership.create!(
      user: @user,
      subscription_type: @simple_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )

    # Adhésion expirée
    expired = UserMembership.create!(
      user: @user,
      subscription_type: @circus_membership,
      start_date: 2.years.ago.to_date,
      end_date: 1.year.ago.to_date,
      status: :active
    )

    assert_includes UserMembership.active, active
    assert_not_includes UserMembership.active, expired
  end

  test "un utilisateur peut avoir une adhésion simple active" do
    membership = user_memberships(:simple_active)
    assert membership.valid?
    assert membership.status_active?
    assert membership.subscription_type.category_basic_membership?
  end

  test "un utilisateur peut avoir une adhésion cirque active" do
    membership = user_memberships(:circus_active)
    assert membership.valid?
    assert membership.status_active?
    assert membership.subscription_type.category_circus_membership?
  end

  test "un bénévole peut avoir une adhésion cirque" do
    membership = user_memberships(:volunteer_membership)
    assert membership.valid?
    assert membership.status_active?
    assert membership.subscription_type.category_circus_membership?
    assert_equal 2, membership.user.role # role bénévole
  end

  test "une adhésion expirée est correctement marquée" do
    membership = user_memberships(:circus_expired)
    assert membership.valid?
    assert membership.status_expired?
    assert membership.end_date <= Date.current
  end

  test "un visiteur peut avoir une adhésion journalière" do
    membership = user_memberships(:visitor_day)
    assert membership.valid?
    assert membership.status_pending?
    assert_equal "day", membership.subscription_type.duration_type
    assert_equal 1, membership.subscription_type.duration_value
  end

  test "les dates d'adhésion sont cohérentes" do
    membership = user_memberships(:simple_active)
    assert membership.start_date <= membership.end_date
    assert_equal membership.start_date.year, membership.year_reference
  end

  test "une adhésion nécessite un utilisateur et un type d'abonnement" do
    membership = UserMembership.new(
      status: "active",
      start_date: Date.current,
      end_date: 1.year.from_now
    )
    assert_not membership.valid?
    assert_includes membership.errors.full_messages, "User must exist"
    assert_includes membership.errors.full_messages, "Subscription type must exist"
  end
end

require "test_helper"

class UserMembershipSubscriptionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "test@example.com",
      first_name: "Test",
      last_name: "User",
      password: "password",
      password_confirmation: "password"
    )
    
    @circus_membership = SubscriptionType.create!(
      name: "Adhésion Cirque",
      category: "circus_membership",
      price: 10,
      active: true
    )
    
    @user_membership = UserMembership.create!(
      user: @user,
      subscription_type: @circus_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )

    @day_pass = SubscriptionType.create!(
      name: "Journée",
      category: "day_pass",
      price: 4,
      active: true
    )

    @ten_pass = SubscriptionType.create!(
      name: "Pack 10",
      category: "ten_pass",
      price: 30,
      active: true
    )

    @trimester = SubscriptionType.create!(
      name: "Trimestre",
      category: "trimester",
      price: 65,
      active: true
    )
  end

  test "souscription valide avec priorité" do
    subscription = UserMembershipSubscription.new(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: Date.current,
      subscription_priority: :day,
      status: :active
    )
    
    assert subscription.valid?
  end

  test "priorité par défaut est 'day'" do
    subscription = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: Date.current,
      status: :active
    )
    
    assert_equal "day", subscription.subscription_priority
  end

  test "vérifie l'ordre des priorités" do
    day = UserMembershipSubscription.new(subscription_priority: :day)
    pack = UserMembershipSubscription.new(subscription_priority: :pack)
    trimester = UserMembershipSubscription.new(subscription_priority: :trimester)
    year = UserMembershipSubscription.new(subscription_priority: :year)
    
    assert day.subscription_priority_before?(pack)
    assert pack.subscription_priority_before?(trimester)
    assert trimester.subscription_priority_before?(year)
  end

  test "scope available retourne uniquement les souscriptions actives et valides" do
    active_future = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: 1.day.from_now.to_date,
      status: :active
    )
    
    expired = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: 2.days.ago.to_date,
      end_date: 1.day.ago.to_date,
      status: :active
    )
    
    inactive = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: 1.day.from_now.to_date,
      status: :cancelled
    )
    
    available = UserMembershipSubscription.available
    assert_includes available, active_future
    assert_not_includes available, expired
    assert_not_includes available, inactive
  end

  test "scope with_remaining_sessions retourne uniquement les pass avec séances restantes" do
    with_sessions = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @ten_pass,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      remaining_sessions: 5,
      status: :active
    )
    
    without_sessions = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @ten_pass,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      remaining_sessions: 0,
      status: :active
    )
    
    assert_includes UserMembershipSubscription.with_remaining_sessions, with_sessions
    assert_not_includes UserMembershipSubscription.with_remaining_sessions, without_sessions
  end

  test "la date de fin doit être après la date de début" do
    subscription = UserMembershipSubscription.new(
      user_membership: @user_membership,
      subscription_type: @trimester,
      start_date: Date.current,
      end_date: 1.day.ago.to_date,
      status: :active
    )
    
    assert_not subscription.valid?
    assert_includes subscription.errors[:end_date], "doit être après la date de début"
  end

  test "ne peut pas avoir de sessions restantes pour un abonnement non limité" do
    subscription = UserMembershipSubscription.new(
      user_membership: @user_membership,
      subscription_type: @trimester,
      start_date: Date.current,
      end_date: 3.months.from_now.to_date,
      remaining_sessions: 5,
      status: :active
    )
    
    assert_not subscription.valid?
    assert_includes subscription.errors[:remaining_sessions], "ne doit être défini que pour les pass 10 séances"
  end

  # Tests de transition de statut
  test "peut passer de pending à active" do
    subscription = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: Date.current,
      status: :pending
    )
    
    subscription.update(status: :active)
    assert subscription.active?
  end

  test "peut suspendre un abonnement actif" do
    subscription = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @trimester,
      start_date: Date.current,
      end_date: 3.months.from_now.to_date,
      status: :active
    )
    
    subscription.update(status: :suspended)
    assert subscription.suspended?
  end

  test "ne peut pas réactiver un abonnement expiré" do
    subscription = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: 2.days.ago.to_date,
      end_date: 1.day.ago.to_date,
      status: :expired
    )
    
    subscription.update(status: :active)
    assert_not subscription.active?
    assert subscription.expired?
  end

  test "marque automatiquement comme expiré quand la date de fin est dépassée" do
    subscription = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @trimester,
      start_date: 3.months.ago.to_date,
      end_date: 1.day.ago.to_date,
      status: :active
    )
    
    subscription.check_expiration
    assert subscription.expired?
  end

  # Tests de renouvellement
  test "peut renouveler un abonnement trimestriel" do
    original = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @trimester,
      start_date: 3.months.ago.to_date,
      end_date: Date.current,
      status: :active
    )
    
    renewal = original.renew
    
    assert_equal original.subscription_type, renewal.subscription_type
    assert_equal Date.current, renewal.start_date
    assert_equal 3.months.from_now.to_date, renewal.end_date
    assert_equal "active", renewal.status
    assert_equal original.subscription_priority, renewal.subscription_priority
  end

  test "peut renouveler un pass 10 séances" do
    original = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @ten_pass,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      remaining_sessions: 0,
      status: :completed
    )
    
    renewal = original.renew
    
    assert_equal original.subscription_type, renewal.subscription_type
    assert_equal 10, renewal.remaining_sessions
    assert_equal "active", renewal.status
  end

  test "ne peut pas renouveler un abonnement journée" do
    original = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: Date.current,
      status: :active
    )
    
    assert_raises(StandardError) { original.renew }
  end

  test "conserve l'historique lors du renouvellement" do
    original = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @trimester,
      start_date: 3.months.ago.to_date,
      end_date: Date.current,
      status: :active
    )
    
    renewal = original.renew
    
    assert_equal "expired", original.reload.status
    assert_equal original.id, renewal.renewed_from_id
  end

  test "incrémente le compteur de renouvellement" do
    original = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @trimester,
      start_date: 3.months.ago.to_date,
      end_date: Date.current,
      status: :active,
      renewal_count: 0
    )
    
    renewal = original.renew
    assert_equal 1, renewal.renewal_count
  end

  test "priorité des souscriptions respectée" do
    day = UserMembershipSubscription.subscription_priorities[:day]
    pack = UserMembershipSubscription.subscription_priorities[:pack]
    trimester = UserMembershipSubscription.subscription_priorities[:trimester]
    year = UserMembershipSubscription.subscription_priorities[:year]
    
    assert day < pack
    assert pack < trimester
    assert trimester < year
  end

  test "souscription journée a la priorité la plus basse" do
    subscription = UserMembershipSubscription.new(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: 1.day.from_now,
      subscription_priority: :day
    )
    assert_equal 0, subscription.subscription_priority
  end

  test "souscription annuelle a la priorité la plus haute" do
    subscription = UserMembershipSubscription.new(
      user_membership: @user_membership,
      subscription_type: @circus_membership,
      start_date: Date.current,
      end_date: 1.year.from_now,
      subscription_priority: :year
    )
    assert_equal 3, subscription.subscription_priority
  end

  test "validation des dates de souscription" do
    subscription = UserMembershipSubscription.new(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.tomorrow,
      end_date: Date.current
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:end_date], "doit être après la date de début"
  end

  test "souscription avec sessions limitées" do
    subscription = UserMembershipSubscription.new(
      user_membership: @user_membership,
      subscription_type: @ten_pass,
      start_date: Date.current,
      remaining_sessions: 10
    )
    assert subscription.valid?
    assert_equal 10, subscription.remaining_sessions
  end

  test "scope available retourne les souscriptions valides" do
    active = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: 1.day.from_now,
      status: :active,
      subscription_priority: :day
    )

    expired = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: 2.days.ago,
      end_date: 1.day.ago,
      status: :expired,
      subscription_priority: :day
    )

    available = UserMembershipSubscription.available
    assert_includes available, active
    assert_not_includes available, expired
  end

  test "scope with_remaining_sessions fonctionne correctement" do
    with_sessions = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @ten_pass,
      start_date: Date.current,
      remaining_sessions: 5,
      status: :active,
      subscription_priority: :pack
    )

    no_sessions = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @ten_pass,
      start_date: Date.current,
      remaining_sessions: 0,
      status: :active,
      subscription_priority: :pack
    )

    with_remaining = UserMembershipSubscription.with_remaining_sessions
    assert_includes with_remaining, with_sessions
    assert_not_includes with_remaining, no_sessions
  end

  test "statut cohérent avec les sessions restantes" do
    subscription = UserMembershipSubscription.create!(
      user_membership: @user_membership,
      subscription_type: @ten_pass,
      start_date: Date.current,
      remaining_sessions: 0,
      status: :active,
      subscription_priority: :pack
    )
    
    assert_equal "expired", subscription.status
  end

  test "impossibilité d'avoir des sessions restantes pour un pass journée" do
    subscription = UserMembershipSubscription.new(
      user_membership: @user_membership,
      subscription_type: @day_pass,
      start_date: Date.current,
      end_date: 1.day.from_now,
      remaining_sessions: 5,
      subscription_priority: :day
    )
    
    assert_not subscription.valid?
  end
end

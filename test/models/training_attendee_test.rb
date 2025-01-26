require "test_helper"

class TrainingAttendeeTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "test@example.com",
      first_name: "Test",
      last_name: "User",
      password: "password",
      password_confirmation: "password"
    )
    
    @admin = User.create!(
      email_address: "admin@example.com",
      first_name: "Admin",
      last_name: "User",
      password: "password",
      password_confirmation: "password",
      role: "admin"
    )
    
    @simple_membership = SubscriptionType.create!(
      name: "Adhésion Simple",
      category: "membership",
      price: 1,
      active: true
    )
    
    @circus_membership = SubscriptionType.create!(
      name: "Adhésion Cirque",
      category: "circus_membership",
      price: 10,
      active: true
    )
    
    @ten_pass = SubscriptionType.create!(
      name: "Pack 10",
      category: "ten_pass",
      price: 30,
      has_limited_sessions: true,
      active: true
    )
    
    @simple_user_membership = UserMembership.create!(
      user: @user,
      subscription_type: @simple_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )
    
    @circus_user_membership = UserMembership.create!(
      user: @user,
      subscription_type: @circus_membership,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active
    )
    
    @ten_pass_subscription = UserMembership.create!(
      user: @user,
      subscription_type: @ten_pass,
      start_date: Date.current,
      end_date: 1.year.from_now.to_date,
      status: :active,
      remaining_sessions: 10
    )
    
    @training_session = TrainingSession.create!(
      date: Date.current,
      status: :open
    )
  end

  test "peut enregistrer une présence avec adhésion et pass valides" do
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      training_session: @training_session
    )
    
    assert attendance.valid?
  end

  test "ne peut pas enregistrer une présence sans adhésion cirque" do
    @circus_user_membership.update!(status: :expired)
    
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      training_session: @training_session
    )
    
    assert_not attendance.valid?
    assert_includes attendance.errors[:base], "L'utilisateur doit avoir une adhésion cirque valide"
  end

  test "ne peut pas enregistrer une présence sans pass d'entraînement valide" do
    @ten_pass_subscription.update!(status: :expired)
    
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      training_session: @training_session
    )
    
    assert_not attendance.valid?
    assert_includes attendance.errors[:base], "L'utilisateur doit avoir un abonnement d'entraînement valide"
  end

  test "ne peut pas enregistrer deux présences pour la même session" do
    # Première présence
    TrainingAttendee.create!(
      user: @user,
      user_membership: @ten_pass_subscription,
      training_session: @training_session
    )

    # Deuxième présence
    duplicate = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      training_session: @training_session
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "est déjà enregistré pour cette session"
  end

  test "ne peut pas enregistrer une présence pour une session fermée" do
    @training_session.update!(status: :closed)
    
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      training_session: @training_session
    )
    
    assert_not attendance.valid?
    assert_includes attendance.errors[:base], "L'enregistrement des présences est fermé pour cette journée"
  end

  test "décremente le nombre de séances restantes pour un pass 10" do
    attendance = TrainingAttendee.create!(
      user: @user,
      user_membership: @ten_pass_subscription,
      training_session: @training_session
    )
    
    @ten_pass_subscription.reload
    assert_equal 9, @ten_pass_subscription.remaining_sessions
  end

  test "marque le pass comme complété quand il n'y a plus de séances" do
    @ten_pass_subscription.update!(remaining_sessions: 1)
    
    attendance = TrainingAttendee.create!(
      user: @user,
      user_membership: @ten_pass_subscription,
      training_session: @training_session
    )
    
    @ten_pass_subscription.reload
    assert_equal 0, @ten_pass_subscription.remaining_sessions
    assert_equal "completed", @ten_pass_subscription.status
  end

  test "présence valide avec pass 10 séances" do
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      checked_by: @admin,
      check_in_time: Time.current
    )
    
    assert attendance.valid?
    assert_difference '@ten_pass_subscription.reload.remaining_sessions', -1 do
      attendance.save!
    end
  end

  test "ne peut pas s'enregistrer deux fois le même jour" do
    TrainingAttendee.create!(
      user: @user,
      user_membership: @ten_pass_subscription,
      checked_by: @admin,
      check_in_time: Time.current
    )
    
    duplicate = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      checked_by: @admin,
      check_in_time: Time.current
    )
    
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "est déjà enregistré pour cette séance"
  end

  test "ne peut pas s'enregistrer sans séances restantes" do
    @ten_pass_subscription.update!(remaining_sessions: 0)
    
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      checked_by: @admin,
      check_in_time: Time.current
    )
    
    assert_not attendance.valid?
    assert_includes attendance.errors[:base], "L'utilisateur n'a plus de séances disponibles"
  end

  test "scopes de filtrage" do
    attendance = TrainingAttendee.create!(
      user: @user,
      user_membership: @ten_pass_subscription,
      checked_by: @admin,
      check_in_time: Time.current
    )
    
    assert_includes TrainingAttendee.today, attendance
    assert_includes TrainingAttendee.by_period(Date.current.beginning_of_day, Date.current.end_of_day), attendance
    assert_includes TrainingAttendee.recorded_by_admin, attendance
  end

  test "adhérent simple peut être enregistré comme visiteur" do
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @simple_user_membership,
      checked_by: @admin,
      check_in_time: Time.current,
      training_session: @training_session,
      is_visitor: true
    )
    
    assert attendance.valid?
  end

  test "adhérent simple ne peut pas être enregistré comme pratiquant" do
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @simple_user_membership,
      checked_by: @admin,
      check_in_time: Time.current,
      training_session: @training_session,
      is_visitor: false
    )
    
    assert_not attendance.valid?
    assert_includes attendance.errors[:base], "L'utilisateur doit avoir une adhésion cirque valide pour pratiquer"
  end

  test "adhérent cirque peut être enregistré comme visiteur" do
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @circus_user_membership,
      checked_by: @admin,
      check_in_time: Time.current,
      training_session: @training_session,
      is_visitor: true
    )
    
    assert attendance.valid?
  end

  test "adhérent cirque avec pass peut être enregistré comme pratiquant" do
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @ten_pass_subscription,
      checked_by: @admin,
      check_in_time: Time.current,
      training_session: @training_session,
      is_visitor: false
    )
    
    assert attendance.valid?
  end

  test "adhérent cirque sans pass ne peut pas être enregistré comme pratiquant" do
    attendance = TrainingAttendee.new(
      user: @user,
      user_membership: @circus_user_membership,
      checked_by: @admin,
      check_in_time: Time.current,
      training_session: @training_session,
      is_visitor: false
    )
    
    assert_not attendance.valid?
    assert_includes attendance.errors[:base], "L'utilisateur doit avoir un abonnement d'entraînement valide pour pratiquer"
  end

  test "ne décremente pas les sessions pour un visiteur" do
    attendance = TrainingAttendee.create!(
      user: @user,
      user_membership: @ten_pass_subscription,
      checked_by: @admin,
      check_in_time: Time.current,
      training_session: @training_session,
      is_visitor: true
    )
    
    @ten_pass_subscription.reload
    assert_equal 10, @ten_pass_subscription.remaining_sessions
  end

  test "présence avec adhésion cirque valide" do
    attendance = TrainingAttendee.new(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "regular"
    )
    assert attendance.valid?
  end

  test "présence impossible avec adhésion expirée" do
    attendance = TrainingAttendee.new(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_expired),
      checked_by: users(:admin),
      check_in_time: Time.current
    )
    assert_not attendance.valid?
  end

  test "présence possible pour un visiteur avec pass journée" do
    attendance = TrainingAttendee.new(
      user: users(:visitor),
      user_membership: user_memberships(:visitor_day),
      checked_by: users(:admin),
      check_in_time: Time.current,
      is_visitor: true
    )
    assert attendance.valid?
  end

  test "présence possible pour un bénévole" do
    attendance = TrainingAttendee.new(
      user: users(:volunteer),
      user_membership: user_memberships(:volunteer_membership),
      checked_by: users(:admin),
      check_in_time: Time.current
    )
    assert attendance.valid?
  end

  test "un utilisateur ne peut pas avoir deux présences le même jour" do
    existing = TrainingAttendee.create!(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current
    )

    duplicate = TrainingAttendee.new(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current + 1.hour
    )
    assert_not duplicate.valid?
  end

  test "seul un admin ou bénévole peut enregistrer une présence" do
    attendance = TrainingAttendee.new(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:simple_member),
      check_in_time: Time.current
    )
    assert_not attendance.valid?

    attendance.checked_by = users(:volunteer)
    assert attendance.valid?

    attendance.checked_by = users(:admin)
    assert attendance.valid?
  end

  test "les références temporelles sont correctement définies" do
    time = Time.current
    attendance = TrainingAttendee.create!(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: time
    )

    assert_equal time.year, attendance.year_reference
    assert_equal time.month, attendance.month_number
    assert_equal time.strftime("%U").to_i, attendance.week_number
  end

  test "les types de présence sont correctement gérés" do
    # Présence d'un membre cirque
    circus_attendance = TrainingAttendee.new(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "circus"
    )
    assert circus_attendance.valid?
    
    # Présence d'un visiteur
    visitor_attendance = TrainingAttendee.new(
      user: users(:visitor),
      user_membership: user_memberships(:simple_active),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "visitor"
    )
    assert visitor_attendance.valid?
    
    # Présence d'un responsable
    admin_attendance = TrainingAttendee.new(
      user: users(:admin),
      user_membership: user_memberships(:admin_membership),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "staff"
    )
    assert admin_attendance.valid?
    
    # Type de présence invalide
    invalid_attendance = TrainingAttendee.new(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "invalid"
    )
    assert_not invalid_attendance.valid?
  end

  test "les présences staff ne sont pas comptées dans les statistiques" do
    # Créer une présence staff
    TrainingAttendee.create!(
      user: users(:admin),
      user_membership: user_memberships(:admin_membership),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "staff"
    )
    
    # Créer une présence normale
    TrainingAttendee.create!(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "circus"
    )
    
    stats = AttendanceStatistic.create_daily_stats(Date.current)
    assert_equal 1, stats.total_visits # Seule la présence normale est comptée
  end

  test "les statistiques distinguent visiteurs et pratiquants" do
    # Présence d'un visiteur
    TrainingAttendee.create!(
      user: users(:visitor),
      user_membership: user_memberships(:simple_active),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "visitor"
    )
    
    # Présence d'un pratiquant
    TrainingAttendee.create!(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current,
      attendance_type: "circus"
    )
    
    stats = AttendanceStatistic.create_daily_stats(Date.current)
    assert_equal 2, stats.total_visits
    assert_equal 1, stats.visitor_count
    assert_equal 1, stats.practice_count
  end

  test "un bénévole peut enregistrer une présence" do
    attendance = TrainingAttendee.new(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:volunteer),
      check_in_time: Time.current
    )
    assert attendance.valid?
  end

  test "un visiteur n'a pas besoin d'abonnement pour être enregistré" do
    attendance = TrainingAttendee.new(
      user: users(:visitor),
      user_membership: user_memberships(:simple_active),
      checked_by: users(:volunteer),
      check_in_time: Time.current,
      is_visitor: true
    )
    assert attendance.valid?
  end

  test "un membre cirque a besoin d'un abonnement pour pratiquer" do
    attendance = TrainingAttendee.new(
      user: users(:circus_member),
      user_membership: user_memberships(:circus_active),
      checked_by: users(:volunteer),
      check_in_time: Time.current,
      is_visitor: false
    )
    
    # Sans abonnement valide
    assert_not attendance.valid?
    
    # Avec un abonnement valide
    attendance.user_membership = user_memberships(:circus_with_subscription)
    assert attendance.valid?
  end

  test "un bénévole peut gérer les adhésions et abonnements" do
    volunteer = users(:volunteer)
    assert_not_nil volunteer
    assert volunteer.can_manage_memberships?
    assert volunteer.can_manage_subscriptions?
  end
end 
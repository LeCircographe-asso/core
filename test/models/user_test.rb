require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @guest = users(:guest)
    @member = users(:member)
    @volunteer = users(:volunteer)
    @admin = users(:admin)
    @godmode = users(:godmode)
    
    # Créer un nouvel utilisateur pour les tests d'adhésion
    @new_user = User.create!(
      email_address: "new_user@example.com",
      password: "password",
      first_name: "New",
      last_name: "User",
      role: :member
    )
  end

  # Tests des rôles
  test "les rôles sont correctement assignés" do
    assert @guest.guest?
    assert @member.member?
    assert @volunteer.volunteer?
    assert @admin.admin?
    assert @godmode.godmode?
  end

  # Tests des permissions de base
  test "permissions des invités" do
    assert_not @guest.has_privileges?
    assert_not @guest.can_manage_users?
    assert_not @guest.can_manage_memberships?
    assert_not @guest.can_manage_attendance?
  end

  test "permissions des membres" do
    assert_not @member.has_privileges?
    assert_not @member.can_manage_users?
    assert_not @member.can_manage_memberships?
    assert_not @member.can_manage_attendance?
  end

  test "permissions des bénévoles" do
    assert @volunteer.has_privileges?
    assert_not @volunteer.can_manage_users?
    assert @volunteer.can_manage_memberships?
    assert @volunteer.can_manage_attendance?
    assert_not @volunteer.can_view_statistics?
  end

  test "permissions des administrateurs" do
    assert @admin.has_privileges?
    assert @admin.can_manage_users?
    assert @admin.can_manage_memberships?
    assert @admin.can_manage_attendance?
    assert @admin.can_view_statistics?
    assert @admin.can_manage_events?
    assert_not @admin.can_edit_settings?
  end

  test "permissions super admin (godmode)" do
    assert @godmode.has_privileges?
    assert @godmode.can_manage_users?
    assert @godmode.can_manage_memberships?
    assert @godmode.can_manage_attendance?
    assert @godmode.can_view_statistics?
    assert @godmode.can_manage_events?
    assert @godmode.can_edit_settings?
  end

  # Tests des adhésions
  test "vérification des adhésions" do
    # Utiliser le type d'adhésion simple existant
    basic_type = subscription_types(:basic_membership)

    UserMembership.create!(
      user: @new_user,
      subscription_type: basic_type,
      start_date: Date.current,
      end_date: 1.year.from_now,
      status: :active
    )

    assert @new_user.active_membership?
    assert @new_user.active_basic_membership?
    assert_not @new_user.active_circus_membership?
    assert_not @new_user.can_access_training?
  end

  test "vérification des adhésions cirque" do
    # Utiliser le type d'adhésion cirque existant
    circus_type = subscription_types(:circus_membership)

    UserMembership.create!(
      user: @new_user,
      subscription_type: circus_type,
      start_date: Date.current,
      end_date: 1.year.from_now,
      status: :active
    )

    assert @new_user.active_membership?
    assert @new_user.active_circus_membership?
    assert_not @new_user.can_access_training?
  end

  test "accès aux entraînements" do
    # Utiliser les types d'abonnement existants
    circus_type = subscription_types(:circus_membership)
    day_pass = subscription_types(:day_pass)

    # Créer les adhésions
    UserMembership.create!(
      user: @new_user,
      subscription_type: circus_type,
      start_date: Date.current,
      end_date: 1.year.from_now,
      status: :active
    )

    UserMembership.create!(
      user: @new_user,
      subscription_type: day_pass,
      start_date: Date.current,
      end_date: 1.day.from_now,
      status: :active
    )

    assert @new_user.can_access_training?
    assert @new_user.active_circus_membership?
    assert @new_user.has_valid_training_pass?
  end

  # Tests des scopes
  test "scopes de filtrage des utilisateurs" do
    assert_includes User.guests, @guest
    assert_includes User.members, @member
    assert_includes User.volunteers, @volunteer
    assert_includes User.admins, @admin
    assert_includes User.godmodes, @godmode
  end
end

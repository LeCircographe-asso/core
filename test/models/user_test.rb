require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "un admin peut tout faire" do
    admin = users(:admin)
    assert admin.can_manage_users?
    assert admin.can_manage_memberships?
    assert admin.can_manage_subscriptions?
    assert admin.can_record_attendance?
    assert admin.can_view_statistics?
  end

  test "un bénévole peut gérer les adhésions et présences" do
    volunteer = users(:volunteer)
    assert volunteer.can_manage_memberships?
    assert volunteer.can_manage_subscriptions?
    assert volunteer.can_record_attendance?
    assert_not volunteer.can_manage_users?
    assert_not volunteer.can_view_statistics?
  end

  test "un membre simple peut voir son profil" do
    simple_member = users(:simple_member)
    assert simple_member.can_view_profile?
    assert_not simple_member.can_manage_memberships?
    assert_not simple_member.can_manage_subscriptions?
    assert_not simple_member.can_record_attendance?
  end

  test "un membre cirque peut voir son profil" do
    circus_member = users(:circus_member)
    assert circus_member.can_view_profile?
    assert_not circus_member.can_manage_memberships?
    assert_not circus_member.can_manage_subscriptions?
    assert_not circus_member.can_record_attendance?
  end

  test "un visiteur n'a pas besoin d'abonnement pour accéder" do
    visitor = users(:visitor)
    assert visitor.can_access_as_visitor?
    assert_not visitor.needs_subscription_for_access?
  end

  test "seuls les membres cirque ont besoin d'abonnement pour la pratique" do
    circus_member = users(:circus_member)
    simple_member = users(:simple_member)
    visitor = users(:visitor)

    assert circus_member.needs_subscription_for_practice?
    assert_not simple_member.needs_subscription_for_practice?
    assert_not visitor.needs_subscription_for_practice?
  end

  test "peut avoir plusieurs rôles simultanément" do
    user = users(:circus_member)
    assert user.has_role?(:circus_member)
    
    # Ajout du rôle bénévole
    user.add_role(:volunteer)
    assert user.has_role?(:volunteer)
    assert user.has_role?(:circus_member)
    
    # Vérifie les permissions combinées
    assert user.can_record_attendance?  # Permission de bénévole
    assert user.needs_subscription_for_practice? # Reste un membre cirque
  end

  test "peut promouvoir un membre cirque en bénévole" do
    user = users(:circus_member)
    assert_not user.can_record_attendance? # Initialement ne peut pas enregistrer les présences
    
    user.add_role(:volunteer)
    assert user.can_record_attendance? # Peut maintenant enregistrer les présences
    assert user.needs_subscription_for_practice? # Garde ses besoins d'abonnement
  end

  test "la suppression d'un utilisateur supprime ses adhésions" do
    user = users(:circus_member)
    membership_count = user.user_memberships.count
    assert membership_count > 0
    
    user.destroy
    assert_equal 0, UserMembership.where(user_id: user.id).count
  end

  test "la suppression d'un utilisateur supprime ses présences" do
    user = users(:circus_member)
    attendance = TrainingAttendee.create!(
      user: user,
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current
    )
    
    assert_difference 'TrainingAttendee.count', -1 do
      user.destroy
    end
  end

  test "un membre simple peut devenir bénévole" do
    user = users(:simple_member)
    assert_not user.can_record_attendance? # Initialement ne peut pas enregistrer les présences
    
    user.add_role(:volunteer)
    assert user.has_role?(:volunteer)
    assert user.has_role?(:simple_member)
    assert user.can_record_attendance? # Peut maintenant enregistrer les présences
  end

  test "un membre cirque peut devenir bénévole" do
    user = users(:circus_member)
    assert_not user.can_record_attendance?
    
    user.add_role(:volunteer)
    assert user.has_role?(:volunteer)
    assert user.has_role?(:circus_member)
    assert user.can_record_attendance?
    assert user.needs_subscription_for_practice? # Garde ses besoins d'abonnement
  end

  test "la suppression d'un utilisateur conserve l'historique anonyme" do
    user = users(:circus_member)
    
    # Créer des présences historiques
    attendance = TrainingAttendee.create!(
      user: user,
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: 1.day.ago
    )
    
    user.destroy
    
    # La présence existe toujours mais est anonymisée
    attendance.reload
    assert_nil attendance.user_id
    assert_not_nil attendance.check_in_time
    assert_not_nil attendance.checked_by_id
  end

  test "la modification du rôle d'un utilisateur conserve ses données" do
    user = users(:circus_member)
    attendance = TrainingAttendee.create!(
      user: user,
      user_membership: user_memberships(:circus_active),
      checked_by: users(:admin),
      check_in_time: Time.current
    )
    
    # Ajout du rôle bénévole
    user.add_role(:volunteer)
    attendance.reload
    
    # Les données de présence sont conservées
    assert_equal user.id, attendance.user_id
    assert_not_nil attendance.check_in_time
  end
end

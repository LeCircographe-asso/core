require "test_helper"

class AttendanceStatisticTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin)
    @circus_member = users(:circus_member)
    @visitor = users(:visitor)
    @today = Date.current
  end

  test "calcule correctement les statistiques journalières" do
    # Créer quelques présences
    3.times do
      TrainingAttendee.create!(
        user: @circus_member,
        user_membership: user_memberships(:circus_active),
        checked_by: @admin,
        check_in_time: Time.current,
        attendance_type: "regular"
      )
    end

    stats = AttendanceStatistic.create_daily_stats(@today)
    assert_equal 3, stats.total_visits
    assert_equal 1, stats.unique_visitors # même utilisateur
    assert_equal "daily", stats.period_type
  end

  test "calcule correctement les statistiques hebdomadaires" do
    # Créer des présences sur plusieurs jours
    3.times do |i|
      TrainingAttendee.create!(
        user: @circus_member,
        user_membership: user_memberships(:circus_active),
        checked_by: @admin,
        check_in_time: i.days.ago,
        attendance_type: "regular"
      )
    end

    stats = AttendanceStatistic.create_weekly_stats(@today)
    assert_equal 3, stats.total_visits
    assert_equal 1, stats.unique_visitors
    assert_equal "weekly", stats.period_type
  end

  test "distingue les types de présence dans les statistiques" do
    # Présence régulière
    TrainingAttendee.create!(
      user: @circus_member,
      user_membership: user_memberships(:circus_active),
      checked_by: @admin,
      check_in_time: Time.current,
      attendance_type: "regular"
    )

    # Présence visiteur
    TrainingAttendee.create!(
      user: @visitor,
      user_membership: user_memberships(:visitor_day),
      checked_by: @admin,
      check_in_time: Time.current,
      attendance_type: "regular",
      is_visitor: true
    )

    stats = AttendanceStatistic.create_daily_stats(@today)
    assert_equal 2, stats.total_visits
    assert_equal 2, stats.unique_visitors
    assert_equal 1, stats.visitor_count
  end

  test "les statistiques sont liées aux présences" do
    attendance = TrainingAttendee.create!(
      user: @circus_member,
      user_membership: user_memberships(:circus_active),
      checked_by: @admin,
      check_in_time: Time.current
    )

    stats = AttendanceStatistic.create_daily_stats(@today)
    assert_includes stats.training_attendees, attendance
  end

  test "met à jour les statistiques quand une présence est ajoutée" do
    stats = AttendanceStatistic.create_daily_stats(@today)
    initial_count = stats.total_visits

    TrainingAttendee.create!(
      user: @circus_member,
      user_membership: user_memberships(:circus_active),
      checked_by: @admin,
      check_in_time: Time.current
    )

    stats.reload
    assert_equal initial_count + 1, stats.total_visits
  end

  test "calcule correctement l'heure de pointe" do
    peak_time = Time.current.change(hour: 14)
    
    # Créer plusieurs présences à la même heure
    3.times do
      TrainingAttendee.create!(
        user: users([:circus_member, :visitor, :simple_member].sample),
        user_membership: user_memberships(:circus_active),
        checked_by: @admin,
        check_in_time: peak_time
      )
    end

    stats = AttendanceStatistic.create_daily_stats(@today)
    assert_equal peak_time.hour, stats.peak_time.hour
    assert_equal 3, stats.peak_attendance
  end
end 
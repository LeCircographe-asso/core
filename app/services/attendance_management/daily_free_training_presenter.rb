module AttendanceManagement
  class DailyFreeTrainingPresenter < BaseService
    attribute :date, :date

    def call
      target_date = (date || Date.current)

      list = AttendanceList.where(list_type: :training)
                           .where(start_date: target_date.beginning_of_day..target_date.end_of_day)
                           .first

      return failure("No training list for #{target_date}") unless list

      attendances = list.attendances.includes(:person, :book_of_entry)
      pack10_sessions = attendances.select { |att| att.book_of_entry&.is_pack10? }.count
      day_passes = attendances.select { |att| att.book_of_entry&.subscription_plan&.duration == "day" }.count

      success(
        attendance_list: list,
        attendances: attendances,
        pack10_sessions: pack10_sessions,
        day_passes: day_passes,
        total_attendances: attendances.count
      )
    end
  end
end

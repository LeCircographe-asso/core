module AttendanceManagement
  class DailyFreeTrainingPresenter < BaseService
    attribute :date, :date

    def call
      target_date = date || Date.current

      list = AttendanceList.where(list_type: :training)
                           .where(start_date: target_date.all_day)
                           .first

      return failure("No training list for #{target_date}") unless list

      attendances = list.attendances.includes(:person, :contribution)
      pack10_sessions = attendances.select { |att| att.contribution&.is_pack10? }.count
      day_passes = attendances.select { |att| att.contribution&.contribution_formula&.duration == 'day' }.count

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

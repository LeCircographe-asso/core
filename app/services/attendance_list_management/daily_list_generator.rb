# frozen_string_literal: true

module AttendanceListManagement
  class DailyListGenerator < BaseService
    attribute :date, :date
    attribute :created_by_id, :integer

    def call
      target_date = date || Date.current

      return failure("Free training closed on Mondays") if target_date.monday?

      return failure("Attendance list already exists for #{target_date}") if attendance_list_exists_for?(target_date)

      start_datetime = build_start_datetime(target_date)
      end_datetime = target_date.end_of_day

      attendance_list = AttendanceList.create!(
        list_type: :training,
        status: :open,
        start_date: start_datetime,
        end_date: end_datetime
      )

      ActiveSupport::Notifications.instrument(
        "attendance_list.daily_created",
        attendance_list_id: attendance_list.id,
        date: target_date,
        created_by_id: created_by_id
      )

      success(attendance_list: attendance_list, message: "Daily attendance list generated")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error "[DailyListGenerator] Error: #{e.message}"
      failure("Error generating attendance list: #{e.message}")
    end

    private

    def attendance_list_exists_for?(target_date)
      AttendanceList.where(list_type: :training)
                    .exists?(start_date: target_date.all_day)
    end

    def build_start_datetime(target_date)
      # Les entraînements libres se déroulent en soirée, on positionne par défaut la liste à 18h00.
      target_date.beginning_of_day + 18.hours
    end
  end
end

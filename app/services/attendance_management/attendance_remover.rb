module AttendanceManagement
  class AttendanceRemover < BaseService
    attribute :attendance_id, :integer
    attribute :deleted_by_id, :integer

    validates :attendance_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      attendance = Attendance.find(attendance_id)
      Attendance.transaction do
        contribution = attendance.contribution
        attendance.destroy!

        if contribution&.has_session_limit?
          contribution.refund_session!
        end

        ActiveSupport::Notifications.instrument(
          "attendance.deleted",
          attendance_id: attendance_id,
          person_id: attendance.person_id,
          attendance_list_id: attendance.attendance_list_id,
          contribution_id: attendance.contribution_id,
          deleted_by_id: deleted_by_id
        )

        success(message: "Attendance removed successfully", contribution: contribution)
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Attendance not found: #{e.message}")
    rescue => e
      Rails.logger.error "[AttendanceRemover] Error: #{e.message}"
      failure("Error removing attendance: #{e.message}")
    end
  end
end

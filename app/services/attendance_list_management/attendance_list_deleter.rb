# frozen_string_literal: true

module AttendanceListManagement
  class AttendanceListDeleter < BaseService
    attribute :attendance_list_id, :integer
    attribute :deleted_by_id, :integer

    validates :attendance_list_id, presence: true
    validates :deleted_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        attendance_list = AttendanceList.find(attendance_list_id)
        User.find(deleted_by_id)

        ActiveRecord::Base.transaction do
          attendance_list.destroy!

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            'attendance_list.deleted',
            attendance_list_id: attendance_list.id,
            name: attendance_list.name,
            deleted_by_id: deleted_by_id
          )

          success(message: 'La liste a été supprimée avec succès.')
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Attendance list or User not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[AttendanceListDeleter] Error: #{e.message}"
        failure("Error deleting attendance list: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end

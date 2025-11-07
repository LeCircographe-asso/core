module AttendanceListManagement
  class AttendanceListUpdater < BaseService
    attribute :attendance_list_id, :integer
    attribute :name, :string
    attribute :status, :string
    attribute :list_type, :string
    attribute :start_date, :datetime
    attribute :updated_by_id, :integer

    validates :attendance_list_id, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        attendance_list = AttendanceList.find(attendance_list_id)
        updated_by = User.find(updated_by_id)

        ActiveRecord::Base.transaction do
          attendance_list.update!(
            name: name || attendance_list.name,
            status: status || attendance_list.status,
            list_type: list_type || attendance_list.list_type,
            start_date: start_date || attendance_list.start_date
          )

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "attendance_list.updated",
            attendance_list_id: attendance_list.id,
            updated_by_id: updated_by_id,
            changes: attendance_list.previous_changes
          )

          success(attendance_list: attendance_list, message: "Liste de présence mise à jour avec succès !")
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Attendance list or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[AttendanceListUpdater] Error: #{e.message}"
        failure("Error updating attendance list: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end

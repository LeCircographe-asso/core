module AttendanceListManagement
  class AttendanceListCreator < BaseService

    attribute :name, :string
    attribute :status, :string
    attribute :list_type, :string
    attribute :start_date, :datetime
    attribute :created_by_id, :integer

    validates :name, presence: true
    validates :start_date, presence: true
    validates :created_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        created_by = User.find(created_by_id)

        # Set default start date to current time if not provided
        actual_start_date = start_date || Time.current

        # Set end date to end of the day (le modèle fait déjà cette logique, mais on la garde pour cohérence)
        end_date = actual_start_date.change(hour: 23, min: 59, sec: 59)

        attendance_list = AttendanceList.create!(
          name: name,
          status: status || "open", # Utiliser l'enum par défaut du modèle (open, close, archived)
          list_type: list_type,
          start_date: actual_start_date,
          end_date: end_date
        )

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "attendance_list.created",
          attendance_list_id: attendance_list.id,
          name: attendance_list.name,
          created_by_id: created_by_id
        )

          success(attendance_list: attendance_list, message: "Liste de présence créée avec succès !")
      rescue ActiveRecord::RecordNotFound => e
        failure("User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[AttendanceListCreator] Error: #{e.message}"
        failure("Error creating attendance list: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end


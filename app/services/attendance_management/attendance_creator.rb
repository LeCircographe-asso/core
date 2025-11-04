module AttendanceManagement
  class AttendanceCreator < BaseService

    attribute :person_id, :integer
    attribute :event_id, :integer
    attribute :attendance_list_id, :integer
    attribute :book_of_entry_id, :integer
    attribute :date, :date

    validates :person_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        person = Person.find(person_id)
        
        attendance = Attendance.create!(
          person: person,
          event_id: event_id,
          attendance_list_id: attendance_list_id,
          book_of_entry_id: book_of_entry_id,
          date: date || Date.current
        )

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "attendance.created",
          attendance_id: attendance.id,
          person_id: person_id,
          event_id: event_id,
          attendance_list_id: attendance_list_id,
          book_of_entry_id: book_of_entry_id
        )

          success(attendance: attendance, message: "Attendance created successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("Person or Event not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[AttendanceCreator] Error: #{e.message}"
        Rails.logger.error "[AttendanceCreator] Backtrace: #{e.backtrace.first(5).join('\n')}"
        failure("Error creating attendance: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end


module EventManagement
  class EventDeleter < BaseService
    attribute :event_id, :integer
    attribute :deleted_by_id, :integer
    attribute :reason, :string

    validates :event_id, presence: true
    validates :deleted_by_id, presence: true
    validates :reason, presence: true

    def call
      return failure("Invalid deletion data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the event and deleter
          event = Event.find(event_id)
          deleted_by = User.find(deleted_by_id)

          # Check if event has participants
          if event.people.any?
            return failure("Cannot delete event with participants. Please remove participants first.")
          end

          # Check if event is in the past and completed
          if event.start_date < Time.current && event.status != "completed"
            return failure("Cannot delete past events that are not completed.")
          end

          # Delete the event
          event.destroy!

          success(event: event, message: "Event deleted successfully")
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Event or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        failure("Unexpected error: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end

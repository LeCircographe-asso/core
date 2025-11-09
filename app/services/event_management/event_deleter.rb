module EventManagement
  class EventDeleter < BaseService
    attribute :event_id, :integer
    attribute :deleted_by_id, :integer
    attribute :reason, :string, default: -> { "Deleted from admin dashboard" }

    validates :event_id, presence: true
    validates :deleted_by_id, presence: true
    validates :reason, presence: true

    def call
      return failure("Invalid deletion data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the event and deleter
          event = Event.find(event_id)
          User.find(deleted_by_id)

          # Remove interest links before deletion to keep related data clean
          event.attendances.destroy_all
          event.event_attendees.destroy_all

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

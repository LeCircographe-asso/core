# frozen_string_literal: true

module EventManagement
  class EventUpdater < BaseService
    attribute :event_id, :integer
    attribute :name, :string
    attribute :upper_description, :string
    attribute :middle_description, :string
    attribute :bottom_description, :string
    attribute :date, :datetime
    attribute :location, :string
    attribute :category, :string
    attribute :updated_by_id, :integer

    validates :event_id, presence: true
    validates :updated_by_id, presence: true
    validates :category, inclusion: { in: %w[show workshop volunteering other] }, allow_blank: true

    def call
      return failure("Invalid update data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the event and updater
          event = Event.find(event_id)
          User.find(updated_by_id)

          # Prepare update attributes (only non-blank values)
          update_attrs = {}
          update_attrs[:name] = name if name.present?
          update_attrs[:upper_description] = upper_description if upper_description.present?
          update_attrs[:middle_description] = middle_description if middle_description.present?
          update_attrs[:bottom_description] = bottom_description if bottom_description.present?
          update_attrs[:date] = date if date.present?
          update_attrs[:location] = location if location.present?
          update_attrs[:category] = category if category.present?

          # Update event
          if event.update!(update_attrs)
            success(event: event, message: 'Event updated successfully')
          else
            failure("Failed to update event: #{event.errors.full_messages.join(', ')}")
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Event or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue StandardError => e
        failure("Unexpected error: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end

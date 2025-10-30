require "ostruct"

module EventManagement
  class EventCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :upper_description, :string
    attribute :middle_description, :string
    attribute :bottom_description, :string
    attribute :date, :datetime
    attribute :location, :string
    attribute :creator_id, :integer
    attribute :category, :string

    validates :name, presence: true
    validates :date, presence: true
    validates :creator_id, presence: true
    validates :category, presence: true, inclusion: { in: %w[show workshop volunteering other] }

    def call
      return failure("Invalid event data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the creator
          creator = User.find(creator_id)

          # Create event
          event = Event.create!(
            name: name,
            upper_description: upper_description,
            middle_description: middle_description,
            bottom_description: bottom_description,
            date: date,
            location: location,
            creator: creator,
            category: category
          )

          success(event: event)
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Creator not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        failure("Unexpected error: #{e.message}")
      end
    end

    private

    def success(data = {})
      OpenStruct.new(success?: true, **data)
    end

    def failure(message)
      OpenStruct.new(success?: false, message: message)
    end
  end
end

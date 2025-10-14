require "ostruct"

module Attendances
  class CheckIn
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :person_id, :integer
    attribute :event_id, :integer
    attribute :date, :date
    attribute :book_of_entry_id, :integer

    validates :person_id, presence: true
    validates :date, presence: true

    def initialize(attributes = {})
      super
      self.date ||= Date.current
    end

    def call
      return failure("Person not found") unless person
      return failure("Already checked in today") if already_checked_in?
      return failure("No valid subscription") unless can_attend?

      ActiveRecord::Base.transaction do
        attendance = create_attendance
        use_subscription_session if book_of_entry
        success(attendance)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def person
      @person ||= Person.find_by(id: person_id)
    end

    def event
      @event ||= Event.find_by(id: event_id) if event_id.present?
    end

    def book_of_entry
      @book_of_entry ||= BookOfEntry.find_by(id: book_of_entry_id) if book_of_entry_id.present?
    end

    def already_checked_in?
      person.attendances.where(date: date).exists?
    end

    def can_attend?
      # Vérifier si la personne a une adhésion active ou un carnet valide
      person.has_active_membership? || (book_of_entry&.can_use?)
    end

    def create_attendance
      Attendance.create!(
        person: person,
        event: event,
        date: date,
        book_of_entry: book_of_entry
      )
    end

    def use_subscription_session
      book_of_entry.use_session! if book_of_entry.can_use?
    end

    def success(attendance)
      OpenStruct.new(
        success?: true,
        attendance: attendance,
        message: "Check-in successful for #{person.full_name}"
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [ message ],
        message: message
      )
    end
  end
end

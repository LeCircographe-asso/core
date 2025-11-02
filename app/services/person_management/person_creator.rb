require "ostruct"

module PersonManagement
  class PersonCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    # Attributs de base
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :address, :string
    attribute :zip_code, :string
    attribute :town, :string
    attribute :country, :string
    attribute :birth_date, :date
    attribute :emergency_contact_name, :string
    attribute :emergency_contact_phone, :string
    attribute :notes, :string
    attribute :occupation, :string
    attribute :specialty, :string
    attribute :image_rights, :boolean, default: false
    attribute :get_involved, :boolean, default: false
    # DEPRECATED: newsletter_subscribed removed - use NewsletterSubscriber model instead
    attribute :dyslexic_font, :boolean, default: false
    attribute :is_minor, :boolean, default: false

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validate :email_uniqueness

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Vérifier si une Person avec cet email existe déjà
          existing_person = Person.active.find_by(email: email)
          if existing_person
            return failure("Person with email #{email} already exists")
          end

          # Créer la Person
          person = Person.create!(person_attributes)

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "person.created",
            person_id: person.id,
            email: email,
            full_name: person.full_name
          )

          success(person)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[PersonCreator] Error: #{e.message}"
        failure("Error creating person: #{e.message}")
      end
    end

    private

    def person_attributes
      {
        first_name: first_name,
        last_name: last_name,
        email: email,
        phone: phone,
        address: address,
        zip_code: zip_code,
        town: town,
        country: country,
        birth_date: birth_date,
        emergency_contact_name: emergency_contact_name,
        emergency_contact_phone: emergency_contact_phone,
        notes: notes,
        occupation: occupation,
        specialty: specialty,
        image_rights: image_rights,
        get_involved: get_involved,
        # DEPRECATED: newsletter_subscribed removed - use NewsletterSubscriber instead
        dyslexic_font: dyslexic_font,
        is_minor: is_minor
      }.compact
    end

    def email_uniqueness
      return if email.blank?

      if Person.active.exists?(email: email)
        errors.add(:email, "has already been taken")
      end
    end

    def success(person)
      OpenStruct.new(
        success?: true,
        person: person,
        message: "Person created successfully"
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [message],
        message: message
      )
    end
  end
end

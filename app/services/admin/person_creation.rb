require "ostruct"

module Admin
  class PersonCreation
    include ActiveModel::Model
    include ActiveModel::Attributes

    # Attributs pour la création de personne
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
    attribute :newsletter_subscribed, :boolean, default: false
    attribute :dyslexic_font, :boolean, default: false

    # Attributs pour l'audit
    attribute :created_by_user_id, :integer

    # Validations
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :created_by_user_id, presence: true
    validate :email_uniqueness
    validate :phone_uniqueness

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      ActiveRecord::Base.transaction do
        # Chercher une Person existante par email ou téléphone
        existing_person = find_existing_person

        if existing_person
          update_existing_person(existing_person)
        else
          create_new_person
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def find_existing_person
      return nil if email.blank? && phone.blank?

      if email.present?
        Person.find_by(email: email)
      elsif phone.present?
        Person.find_by(phone: phone)
      end
    end

    def update_existing_person(person)
      person.update!(
        first_name: first_name,
        last_name: last_name,
        email: email.present? ? email : person.email,
        phone: phone.present? ? phone : person.phone,
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
        newsletter_subscribed: newsletter_subscribed,
        dyslexic_font: dyslexic_font
      )

      success(person, "Person updated successfully: #{person.full_name}")
    end

    def create_new_person
      person = Person.create!(
        first_name: first_name,
        last_name: last_name,
        email: email.present? ? email : nil,
        phone: phone.present? ? phone : nil,
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
        newsletter_subscribed: newsletter_subscribed,
        dyslexic_font: dyslexic_font
      )

      success(person, "Person created successfully: #{person.full_name}")
    end

    def email_uniqueness
      return if email.blank?

      # Vérifier l'unicité dans Person
      if Person.where(email: email).where.not(id: nil).exists?
        errors.add(:email, "has already been taken")
      end

      # Vérifier s'il existe un User avec le même email mais sans Person liée
      if User.where(email_address: email).where(person_id: nil).exists?
        errors.add(:email, "is already used by an existing user account")
      end
    end

    def phone_uniqueness
      return if phone.blank?

      if Person.where(phone: phone).where.not(id: nil).exists?
        errors.add(:phone, "has already been taken")
      end
    end

    def success(person, message)
      OpenStruct.new(
        success?: true,
        person: person,
        message: message
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

require "ostruct"

module People
  class PersonCreator
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

    # Validations
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true, if: -> { newsletter_subscribed == true }
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
      # Chercher par email d'abord (priorité)
      if email.present?
        existing_person = Person.find_by(email: email)
        return existing_person if existing_person
      end

      # Chercher par téléphone si pas d'email ou pas trouvé
      if phone.present?
        existing_person = Person.find_by(phone: phone)
        return existing_person if existing_person
      end

      nil
    end

    def update_existing_person(person)
      # Mettre à jour les informations si nécessaire
      person.update!(
        first_name: first_name,
        last_name: last_name,
        email: email.present? ? email : person.email, # Garder l'email existant si nouveau vide
        phone: phone.present? ? phone : person.phone, # Garder le téléphone existant si nouveau vide
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
      # Créer une nouvelle Person
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
      if Person.where(email: email).where.not(id: person_id_for_validation).exists?
        errors.add(:email, "has already been taken")
      end

      # Vérifier s'il existe un User avec le même email mais sans Person liée
      # (cas où User existe mais Person n'existe pas encore)
      if User.where(email_address: email).where(person_id: nil).exists?
        errors.add(:email, "is already used by an existing user account")
      end
    end

    def phone_uniqueness
      return if phone.blank?

      if Person.where(phone: phone).where.not(id: person_id_for_validation).exists?
        errors.add(:phone, "has already been taken")
      end
    end

    def person_id_for_validation
      # Pour les validations lors de la mise à jour
      @existing_person&.id
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
        errors: [message],
        message: message
      )
    end
  end
end
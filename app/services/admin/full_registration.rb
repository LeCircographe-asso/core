require "ostruct"

module Admin
  class FullRegistration
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

    # Attributs pour la création de compte utilisateur
    attribute :user_email, :string
    attribute :user_password, :string
    attribute :user_system_role, :string, default: "web_visitor"

    # Attributs pour l'adhésion et paiement
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer

    # Validations
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :user_email, presence: true
    validates :user_password, presence: true
    validates :user_system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }
    validates :membership_type_id, presence: { message: "Une adhésion est obligatoire" }
    validates :recorded_by_id, presence: true
    validate :email_uniqueness
    validate :phone_uniqueness
    validate :user_email_uniqueness

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      ActiveRecord::Base.transaction do
        # 1. Créer ou trouver la Person
        person_result = create_or_find_person
        return failure(person_result.errors.join(", ")) unless person_result.success?

        person = person_result.person
        person.skip_membership_validation = true # Permettre création

        # 2. Créer le compte utilisateur
        user_result = create_user_account(person)
        return failure(user_result.errors.join(", ")) unless user_result.success?

        # 3. Créer l'adhésion et le paiement
        membership_result = create_membership(person)
        return failure(membership_result.errors.join(", ")) unless membership_result.success?

        success(person, user_result.user, membership_result.membership)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def create_or_find_person
      # Chercher une Person existante par email
      existing_person = Person.find_by(email: email)

      if existing_person
        # Mettre à jour la Person existante
        existing_person.update!(
          first_name: first_name,
          last_name: last_name,
          email: email.present? ? email : existing_person.email,
          phone: phone.present? ? phone : existing_person.phone,
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
        success(existing_person, "Person updated")
      else
        # Créer une nouvelle Person
        People::PersonCreator.new(
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
          newsletter_subscribed: newsletter_subscribed,
          dyslexic_font: dyslexic_font
        ).call
      end
    end

    def create_user_account(person)
      # Vérifier si la Person a déjà un User
      if person.user.present?
        # Mettre à jour le User existant
        person.user.update!(
          email_address: user_email,
          password: user_password,
          password_confirmation: user_password,
          system_role: user_system_role
        )
        success(person.user, "User account updated")
      else
        # Créer un nouveau User
        People::UserAccountCreator.new(
          person: person,
          user_email: user_email,
          user_password: user_password,
          user_system_role: user_system_role,
          created_by_admin: true # Créé par admin
        ).call
      end
    end

    def create_membership(person)
      People::MembershipCreator.new(
        person: person,
        membership_type_id: membership_type_id,
        payment_method: payment_method,
        recorded_by_id: recorded_by_id
      ).call
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

    def user_email_uniqueness
      return if user_email.blank?

      # Vérifier l'unicité dans User
      if User.where(email_address: user_email).where.not(person_id: nil).exists?
        errors.add(:user_email, "has already been taken")
      end
    end

    def success(person, user, membership, message = "Admin full registration successful")
      OpenStruct.new(
        success?: true,
        person: person,
        user: user,
        membership: membership,
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

require "ostruct"

module People
  class Register
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
    attribute :create_user_account, :boolean, default: false
    attribute :user_email, :string
    attribute :user_system_role, :string, default: "web_visitor"
    attribute :user_password, :string

    # Attributs pour l'adhésion et paiement
    attribute :create_membership, :boolean, default: false
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer

    # Validations principales
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :user_email, presence: true, if: -> { create_user_account == true }
    validates :user_password, presence: true, if: -> { create_user_account == true }
    validates :membership_type_id, presence: { message: "Une adhésion est obligatoire" }

    def call
      return failure("Invalid data") unless valid?

      ActiveRecord::Base.transaction do
        # 1. Créer ou mettre à jour la personne
        person_result = create_person
        return failure(person_result.errors.join(", ")) unless person_result.success?

        person = person_result.person
        person.skip_membership_validation = true # Permettre création

        # 2. Créer le compte utilisateur si demandé
        user_result = create_user_account_service(person) if create_user_account == true
        return failure(user_result.errors.join(", ")) unless user_result.nil? || user_result.success?

        # 3. Créer l'adhésion et le paiement
        membership_result = create_membership(person)
        return failure(membership_result.errors.join(", ")) unless membership_result.success?

        success(person, user_result&.user, membership_result.membership)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    rescue ActiveRecord::Rollback => e
      failure(e.message)
    end

    private

    def create_person
      People::PersonCreator.new(person_attributes).call
    end

    def create_user_account_service(person)
      People::UserAccountCreator.new(
        person: person,
        user_email: user_email,
        user_password: user_password,
        user_system_role: user_system_role
      ).call
    end

    def create_membership(person)
      People::MembershipCreator.new(
        person: person,
        membership_type_id: membership_type_id,
        payment_method: payment_method,
        recorded_by_id: recorded_by_id
      ).call
    end

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
        newsletter_subscribed: newsletter_subscribed,
        dyslexic_font: dyslexic_font
      }
    end

    def success(person, user = nil, membership = nil)
      OpenStruct.new(
        success?: true,
        person: person,
        user: user,
        membership: membership,
        message: "Person registered successfully: #{person.full_name}"
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

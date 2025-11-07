require "ostruct"

module Admin
  class UserCreationForm
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
    attribute :specialty, :string
    attribute :is_minor, :boolean, default: false
    attribute :image_rights, :boolean, default: false
    attribute :get_involved, :boolean, default: false
    attribute :newsletter_subscribed, :boolean, default: false
    attribute :dyslexic_font, :boolean, default: false
    attribute :reduced_rate_eligible, :boolean, default: false
    attribute :reduced_rate_reason, :string
    attribute :reduced_rate_proof, :string

    # Attributs pour la création de compte utilisateur
    attribute :create_web_account, :boolean, default: false
    attribute :email_address, :string
    attribute :system_role, :string, default: "web_visitor"

    # Attributs pour l'adhésion
    attribute :create_membership, :boolean, default: false
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"

    # ID de personne existante (si on crée un compte pour une personne existante)
    attribute :person_id, :integer

    validates :first_name, presence: true, if: -> { person_id.blank? }
    validates :last_name, presence: true, if: -> { person_id.blank? }
    validates :email_address, presence: true, if: -> { create_web_account == true }
    validates :system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }
    validates :membership_type_id, presence: true, if: -> { create_membership == true }
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      ActiveRecord::Base.transaction do
        if person_id.present?
          create_user_for_existing_person
        else
          create_person_and_user
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def create_user_for_existing_person
      person = Person.active.find(person_id)

      # Vérifier si cette personne a déjà un compte User
      if person.user.present?
        return failure("Cette personne a déjà un compte web. ID User: #{person.user.id}")
      end

      # Créer le User si compte web demandé
      if create_web_account == true
        # Un compte web nécessite un email
        if person.email.blank? && email_address.blank?
          return failure("Un email est obligatoire pour créer un compte web.")
        end

        result = UserManagement::AccountCreator.new(
          person: person,
          user_email: email_address.presence || person.email,
          user_password: SecureRandom.hex(8),
          user_system_role: system_role,
          created_by_admin: true,
          cgu: true,
          privacy_policy: true
        ).call

        return failure(result.errors.join(", ")) unless result.success?
      end

      success(person, "Compte web créé avec succès !")
    end

    def create_person_and_user
      begin
        # Créer une nouvelle Person directement (sans newsletter_subscribed)
        person = Person.create!(person_attributes.except(:newsletter_subscribed))

        # Créer NewsletterSubscriber si demandé (nouvelle logique)
        if newsletter_subscribed == true && person.email.present?
          NewsletterSubscriber.create!(
            email: person.email,
            person: person,
            source: "admin",
            subscribed: true
          )
        end

        # Créer le User si compte web demandé
        if create_web_account == true
          user = person.build_user(
            email_address: email_address,
            password: SecureRandom.hex(8),
            system_role: system_role,
            created_by_admin: true
          )
          user.cgu = true
          user.privacy_policy = true
          user.save!
        end

        # Créer l'adhésion si demandée
        if create_membership == true
          membership_type = MembershipType.find(membership_type_id)
          person.create_membership!(
            membership_type,
            payment_method: payment_method,
            recorded_by: Current.user
          )
        end

        success(person, "Personne et compte créés avec succès !")
      rescue ActiveRecord::RecordInvalid => e
        failure("Erreur de validation: #{e.message}")
      rescue => e
        failure("Erreur lors de la création: #{e.message}")
      end
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
        specialty: specialty,
        is_minor: is_minor,
        image_rights: image_rights,
        get_involved: get_involved,
        newsletter_subscribed: newsletter_subscribed,
        dyslexic_font: dyslexic_font,
        reduced_rate_eligible: reduced_rate_eligible,
        reduced_rate_reason: reduced_rate_reason,
        reduced_rate_proof: reduced_rate_proof
      }
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

require "ostruct"

module People
  class Register
    include ActiveModel::Model
    include ActiveModel::Attributes

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
    attribute :create_user_account, :boolean, default: false
    attribute :user_email, :string
    attribute :user_system_role, :string, default: "user_connected"
    attribute :user_password, :string

    # Adhésion et paiement
    attribute :create_membership, :boolean, default: false
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :user_email, presence: true, if: -> { create_user_account == true }
    validates :user_password, presence: true, if: -> { create_user_account == true }
    validates :membership_type_id, presence: { message: "Une adhésion est obligatoire" }
    validate :email_uniqueness
    validate :phone_uniqueness
    validate :user_email_uniqueness

    def call
      return failure("Invalid data") unless valid?

      ActiveRecord::Base.transaction do
        person = find_or_create_person
        person.skip_membership_validation = true # Permettre création
        create_membership_and_payment # TOUJOURS créer adhésion
        create_user_account_record if create_user_account == true
        success(person)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def find_or_create_person
      # Chercher une Person existante par email ou téléphone (seulement si présents)
      existing_person = Person.find_by(email: email) if email.present?
      existing_person ||= Person.find_by(phone: phone) if phone.present?

      if existing_person
        # Mettre à jour les informations si nécessaire
        existing_person.update!(
          first_name: first_name,
          last_name: last_name,
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
        @created_person = existing_person
      else
        # Créer une nouvelle Person (email et phone peuvent être nil si vides)
        @created_person = Person.create!(
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
      end

      @created_person
    end

    def create_user_account_record
      return unless create_user_account == true && user_password.present?

      # Vérifier si la Person a déjà un User
      if @created_person.user.present?
        # Mettre à jour le User existant
        @created_person.user.update!(
          email_address: user_email || email,
          password: user_password,
          password_confirmation: user_password,
          system_role: user_system_role
        )
      else
        # Générer un mot de passe temporaire si non fourni
        temp_password = user_password.present? ? user_password : SecureRandom.hex(8)

        User.create!(
          person: @created_person,
          email_address: user_email || email,
          password: temp_password,
          password_confirmation: temp_password,
          system_role: user_system_role
        )
      end
    end

    def create_membership_and_payment
      return unless membership_type_id.present?

      # Créer l'adhésion
      membership = @created_person.memberships.create!(
        membership_type_id: membership_type_id,
        started_at: Time.current,
        ended_at: 1.year.from_now,
        status: "active",
        first_joined_at: Time.current
      )

      # Créer le paiement
      membership_type = MembershipType.find(membership_type_id)
      
      # Trouver un admin pour recorded_by si non fourni
      admin_user = recorded_by_id ? User.find(recorded_by_id) : User.find_by(system_role: [:admin, :super_admin])
      
      payment = Payment.create!(
        person: @created_person,
        recorded_by: admin_user,
        total_cents: membership_type.price_cents,
        payment_method: payment_method,
        status: "success",
        notes: "Paiement pour adhésion #{membership_type.name}"
      )

      # Créer la ligne de paiement
      PaymentLine.create!(
        payment: payment,
        item: membership,
        amount_cents: membership_type.price_cents,
        description: "Adhésion #{membership_type.name}"
      )

      # Traiter le paiement
      Payments::Process.new(payment).call
    end

    def person
      @person ||= Person.find_by(email: email) if email.present?
    end

    def email_uniqueness
      return if email.blank?

      if Person.exists?(email: email)
        errors.add(:email, "has already been taken")
      end
    end

    def phone_uniqueness
      return if phone.blank?

      if Person.exists?(phone: phone)
        errors.add(:phone, "has already been taken")
      end
    end

    def user_email_uniqueness
      return if user_email.blank?

      if User.exists?(email_address: user_email)
        errors.add(:user_email, "has already been taken")
      end
    end

    def success(person)
      OpenStruct.new(
        success?: true,
        person: person,
        user: @created_person&.user,
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

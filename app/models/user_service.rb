class UserService
  def self.create_user_with_membership(user_params, created_by_admin = false)
    # Gérer l'email (générer un email temporaire si vide)
    email = user_params[:email_address]
    if email.blank?
      # Générer un email temporaire unique
      email = "temp.user.#{SecureRandom.hex(8)}@temp.circographe.local"
    end

    # Vérifier si l'email existe déjà dans users ou people
    if User.exists?(email_address: email) || Person.exists?(email: email)
      return { success: false, errors: [ "Cet email est déjà utilisé" ] }
    end

    # Mettre à jour les paramètres avec l'email (potentiellement généré)
    user_params_with_email = user_params.dup
    user_params_with_email[:email_address] = email

    user = User.new(user_params_with_email)
    user.created_by_admin = created_by_admin
    user.password = SecureRandom.hex(10) if created_by_admin

    User.transaction do
      if user.save
        # Créer une Person associée
        person_attributes = {
          first_name: user_params[:first_name],
          last_name: user_params[:last_name],
          phone: user_params[:phone_number].present? ? user_params[:phone_number] : nil,
          address: user_params[:address],
          birth_date: user_params[:birthdate],
          occupation: user_params[:occupation],
          specialty: user_params[:specialty],
          image_rights: user_params[:image_rights] || false,
          get_involved: user_params[:get_involved] || false,
          dyslexic_font: user_params[:dyslexic_font] || false
        }

        # Ajouter l'email seulement si l'utilisateur avait un email original
        person_attributes[:email] = email if user_params[:email_address].present?

        person = Person.create!(person_attributes)

        # Associer l'utilisateur à la personne
        user.update!(person: person)

        # Create initial order (garder pour compatibilité)
        order = user.orders.create!

        return { success: true, user: user, order: order }
      else
        return { success: false, errors: user.errors.full_messages }
      end
    end
  end

  def self.update_user_role(user, new_role)
    return { success: false, message: "Utilisateur non trouvé" } unless user

    if user.update(system_role: new_role)
      { success: true, user: user }
    else
      { success: false, errors: user.errors.full_messages }
    end
  end

  def self.users_count_by_period(start_date, end_date)
    User.where(created_at: start_date..end_date).count
  end

  def self.new_users_count
    users_count_by_period(1.day.ago.beginning_of_day, 1.day.ago.end_of_day)
  end

  def self.users_this_month
    users_count_by_period(Time.current.beginning_of_month, Time.current)
  end

  def self.users_with_active_memberships
    User.joins(:user_memberships).where(user_memberships: { status: :active }).distinct
  end
end

require "ostruct"

module Admin
  module Operations
    class AttendanceOperations
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :actor
      validates :actor, presence: true

      # Vérifier l'éligibilité pour la présence
      def check_eligibility_for(person:, date: Date.current)
        return failure("Invalid actor") unless actor.present?
        return failure("Person is required") unless person.present?

        # Vérifier si déjà présent
        if person.attendances.where(date: date).exists?
          return already_present(person, date)
        end

        # Vérifier adhésion active
        unless person.has_active_membership?
          return no_membership(person)
        end

        # Chercher un carnet utilisable
        usable_book = person.book_of_entries.usable.first

        if usable_book
          needs_book_confirmation(person, usable_book, date)
        else
          # Si pas de carnet mais adhésion active, on peut quand même enregistrer la présence
          # (pour les adhésions annuelles, basiques, etc.)
          can_record_directly(person, date)
        end
      end

      # Enregistrer présence sans carnet (adhésion directe)
      def record_directly(person:, date: Date.current)
        return failure("Invalid actor") unless actor.present?

        ActiveRecord::Base.transaction do
          # Créer ou trouver la liste de présence du jour pour les entraînements libres
          attendance_list = find_or_create_training_list_for_date(date)
          
          attendance = Attendance.create!(
            person: person,
            date: date,
            attendance_list: attendance_list
          )

          Rails.logger.info("[ATTENDANCE] #{actor.email_address} enregistré présence de #{person.full_name} (adhésion directe) dans la liste #{attendance_list.id}")

          success(attendance, "Présence enregistrée (adhésion #{person.current_membership.membership_type.name})")
        end
      rescue => e
        failure(e.message)
      end

      # Enregistrer présence avec carnet
      def record_with_book(person:, book_of_entry:, date: Date.current)
        return failure("Invalid actor") unless actor.present?

        ActiveRecord::Base.transaction do
          # Créer ou trouver la liste de présence du jour pour les entraînements libres
          attendance_list = find_or_create_training_list_for_date(date)
          
          attendance = Attendance.create!(
            person: person,
            date: date,
            book_of_entry: book_of_entry,
            attendance_list: attendance_list
          )

          book_of_entry.use_session!

          Rails.logger.info("[ATTENDANCE] #{actor.email_address} enregistré présence de #{person.full_name} avec carnet #{book_of_entry.id} dans la liste #{attendance_list.id}")

          success(attendance, "Présence enregistrée (#{book_of_entry.sessions_remaining} séances restantes)")
        end
      rescue => e
        failure(e.message)
      end

      private

      def already_present(person, date)
        OpenStruct.new(
          success?: false,
          already_present?: true,
          message: "#{person.full_name} est déjà présent le #{date.strftime('%d/%m/%Y')}"
        )
      end

      def no_membership(person)
        OpenStruct.new(
          success?: false,
          no_membership?: true,
          message: "#{person.full_name} n'a pas d'adhésion active"
        )
      end

      def needs_book_confirmation(person, book_of_entry, date)
        OpenStruct.new(
          success?: false,
          needs_confirmation?: true,
          person: person,
          book_of_entry: book_of_entry,
          sessions_remaining: book_of_entry.sessions_remaining,
          date: date,
          message: "Confirmation requise"
        )
      end

      def needs_subscription(person, date)
        available_plans = SubscriptionPlan.where(
          membership_type: person.current_membership.membership_type
        )

        OpenStruct.new(
          success?: false,
          needs_subscription?: true,
          person: person,
          available_plans: available_plans,
          date: date,
          message: "Aucune cotisation disponible"
        )
      end

      def can_record_directly(person, date)
        OpenStruct.new(
          success?: false,
          can_record_directly?: true,
          person: person,
          date: date,
          membership_type: person.current_membership.membership_type.name,
          message: "Enregistrement direct possible"
        )
      end

      def success(attendance, message)
        OpenStruct.new(success?: true, attendance: attendance, message: message)
      end

      def failure(message)
        OpenStruct.new(success?: false, errors: [message], message: message)
      end

      def find_or_create_training_list_for_date(date)
        # Utiliser find_or_create_by pour éviter les doublons
        AttendanceList.find_or_create_by(
          list_type: :training,
          start_date: date,
          end_date: date + 1.day
        ) do |list|
          list.name = "Entraînement libre #{date.strftime('%d/%m/%Y')}"
          list.status = :open
        end
      end
    end
  end
end

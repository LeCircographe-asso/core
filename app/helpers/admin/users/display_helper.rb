module Admin
  module Users
    module DisplayHelper
      # Formatage du nom avec fallback
      def display_name(person)
        if person.full_name.present?
          person.full_name
        else
          content_tag :span, "Non renseigné", class: "text-gray-400 italic"
        end
      end

      # Formatage de l'email avec fallback
      def display_email(person)
        if person.user&.email_address.present?
          person.user.email_address
        elsif person.email.present?
          content_tag :span, person.email, class: "text-gray-600"
        else
          content_tag :span, "Pas d'email", class: "text-gray-400 italic"
        end
      end

      # Formatage du téléphone avec fallback
      def display_phone(person)
        if person.phone.present?
          format_phone_number(person.phone)
        else
          content_tag :span, "Non renseigné", class: "text-gray-400 italic"
        end
      end
    end
  end
end

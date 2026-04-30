# frozen_string_literal: true

module Admin
  module Users
    module DisplayHelper
      # Formatage du nom avec fallback
      def display_name(person)
        person.full_name.presence || content_tag(:span, "Non renseigné", class: "text-gray-400 italic")
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

      # Formatage du numéro de membre
      def format_member_number(number)
        number.present? ? "##{number}" : "-"
      end

      # Formatage du nom complet
      def format_full_name(person)
        if person.first_name.present? && person.last_name.present?
          "#{person.first_name} #{person.last_name}"
        elsif person.first_name.present?
          person.first_name
        elsif person.last_name.present?
          person.last_name
        else
          "Nom non renseigné"
        end
      end

      # Formatage de la date
      def format_display_date(date)
        return "-" if date.blank?

        if date.is_a?(String)
          Date.parse(date).strftime("%d/%m/%Y")
        else
          date.strftime("%d/%m/%Y")
        end
      rescue StandardError
        "-"
      end

      # Formatage de la monnaie
      def format_currency(amount)
        return "-" if amount.blank?

        number_to_currency(amount, unit: "€", separator: ",", delimiter: " ")
      end
    end
  end
end

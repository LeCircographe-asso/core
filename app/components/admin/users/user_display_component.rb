module Admin
  module Users
    class UserDisplayComponent < ViewComponent::Base
      def initialize(person:)
        @person = person
      end

      private

      attr_reader :person

      def display_name
        if person.full_name.present?
          person.full_name
        else
          content_tag :span, "Non renseigné", class: "text-gray-400 italic"
        end
      end

      def display_email
        if person.user&.email_address.present?
          person.user.email_address
        elsif person.email.present?
          content_tag :span, person.email, class: "text-gray-600"
        else
          content_tag :span, "Pas d'email", class: "text-gray-400 italic"
        end
      end

      def display_phone
        if person.phone.present?
          format_phone_number(person.phone)
        else
          content_tag :span, "Non renseigné", class: "text-gray-400 italic"
        end
      end

      def format_member_number(number)
        number.present? ? "##{number}" : "-"
      end

      def format_full_name
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

      def format_display_date(date)
        return "-" if date.blank?

        if date.is_a?(String)
          Date.parse(date).strftime("%d/%m/%Y")
        else
          date.strftime("%d/%m/%Y")
        end
      rescue
        "-"
      end

      def format_currency(amount)
        return "-" if amount.blank?

        number_to_currency(amount, unit: "€", separator: ",", delimiter: " ")
      end
    end
  end
end

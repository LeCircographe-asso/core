module Admin
  module PaymentsHelper
    def payment_date_display(payment)
      if payment.created_at.present?
        payment.created_at.strftime("%d/%m/%Y")
      else
        "-"
      end
    end

    def payment_person_display(payment)
      if payment.person.present?
        if payment.person.full_name.present?
          payment.person.full_name
        else
          "Personne ##{payment.person.id}"
        end
      else
        "Personne inconnue"
      end
    end

    def payment_status_display(payment)
      status_class = case payment.status
      when "success" then "bg-green-100 text-green-800"
      when "pending" then "bg-yellow-100 text-yellow-800"
      when "cancel" then "bg-red-100 text-red-800"
      else "bg-gray-100 text-gray-800"
      end

      content_tag :span,
                  class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{status_class}" do
        payment.status.humanize
      end
    end

    def payment_method_display(payment)
      case payment.payment_method
      when "cash"
        "Espèces"
      when "card"
        "Carte"
      when "cheque"
        "Chèque"
      when "transfer"
        "Virement"
      when "offered"
        "Offert"
      else
        payment.payment_method.humanize
      end
    end

    def payment_lines_display(payment)
      if payment.payment_lines.any?
        payment.payment_lines.map do |line|
          content_tag :div, class: "text-xs" do
            "#{line.description || line.item_type}: #{number_to_currency(line.amount_cents / 100.0, unit: "€", separator: ",", delimiter: " ")}"
          end
        end.join.html_safe
      else
        content_tag :span, "-", class: "text-gray-400"
      end
    end

    def payment_amount_display(payment)
      return "-" if payment.total_cents.blank?

      number_to_currency(payment.total_cents / 100.0, unit: "€", separator: ",", delimiter: " ")
    end

    def payment_recorded_by_display(payment)
      if payment.recorded_by.present?
        payment.recorded_by.email_address || "Utilisateur ##{payment.recorded_by.id}"
      else
        "Inconnu"
      end
    end
  end
end

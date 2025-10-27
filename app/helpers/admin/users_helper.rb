module Admin
  module UsersHelper
    # REMOVED: Migré vers MembershipStatusBadgeComponent

    # REMOVED: Migré vers MembershipTypeBadgeComponent

    # REMOVED: Migré vers SubscriptionStatusBadgeComponent

    # REMOVED: Migré vers WebAccountIconComponent

    # REMOVED: Migré vers ContextualActionsComponent

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

    # Actions dynamiques pour l'adhésion
    def membership_action_button(person)
      current_membership = person.current_membership

      if current_membership.nil?
        # Pas d'adhésion active
        link_to "Ajouter une adhésion",
                new_admin_membership_path(person_id: person.id),
                class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
      elsif current_membership.membership_type.basic?
        # Adhésion basique -> peut upgrader vers cirque
        link_to "Upgrader vers Cirque",
                new_admin_membership_path(person_id: person.id, upgrade: true),
                class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
      elsif current_membership.membership_type.circus?
        # Adhésion cirque -> peut renouveler
        if current_membership.ended_at < 30.days.from_now
          link_to "Renouveler adhésion",
                  new_admin_membership_path(person_id: person.id, renew: true),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        else
          # Adhésion cirque valide -> pas de bouton
          content_tag :span, "Adhésion Cirque active",
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
        end
      else
        # Autres cas -> renouveler
        link_to "Renouveler adhésion",
                new_admin_membership_path(person_id: person.id, renew: true),
                class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
      end
    end

    # Actions dynamiques pour les cotisations
    def subscription_action_button(person)
      current_membership = person.current_membership

      if current_membership.nil?
        # Pas d'adhésion -> pas de cotisation possible
        content_tag :span, "Adhésion requise",
                    class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
      elsif current_membership.membership_type.basic?
        # Adhésion basique -> pas de cotisation
        content_tag :span, "Adhésion Basique",
                    class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
      elsif current_membership.membership_type.circus?
        # Adhésion cirque -> peut ajouter des cotisations
        active_book = person.book_of_entries.active.first

        if active_book && active_book.remaining_entries > 0
          link_to "Voir cotisation (#{active_book.remaining_entries} restantes)",
                  admin_user_path(person.user ? person.user.id : "person_#{person.id}"),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        else
          link_to "Ajouter une cotisation",
                  new_admin_subscription_plan_path(person_id: person.id),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        end
      else
        # Autres cas
        content_tag :span, "Non applicable",
                    class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
      end
    end

    # Affichage du numéro d'adhérent avec historique
    def member_number_display(person)
      if person.member_number.present?
        # Numéro actuel avec badge
        current_number = content_tag :span,
          class: "member-number-current px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-indigo-100 text-indigo-800" do
          person.member_number
        end

        # Historique si disponible
        history_count = person.member_number_history.count
        if history_count > 1
          history_badge = content_tag :span,
            class: "member-number-history px-1 inline-flex text-xs leading-4 font-medium rounded bg-gray-100 text-gray-600 ml-1",
            title: "Historique: #{history_count} numéro(s)",
            data: {
              controller: "tooltip",
              tooltip_content: "Historique: #{history_count} numéro(s)"
            } do
            "+#{history_count - 1}"
          end
          current_number + history_badge
        else
          current_number
        end
      else
        content_tag :span,
          class: "member-number-missing px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-500" do
          "Non assigné"
        end
      end
    end

    # Détails de l'historique des numéros d'adhérent
    def member_number_history_details(person)
      return "" unless person.member_number_history.exists?

      history_items = person.member_number_history.order(:assigned_at).map do |history|
        status = history.current? ? "ACTUEL" : "PRÉCÉDENT"
        duration = history.duration / 1.day
        duration_text = history.current? ? "" : " (#{duration.round(1)}j)"

        content_tag :div, class: "history-item text-xs py-1 border-b border-gray-100 last:border-b-0" do
          content_tag(:span, "#{history.member_number} (#{status})", class: "font-mono font-semibold") +
          content_tag(:br) +
          content_tag(:span, history.notes, class: "text-gray-600") +
          content_tag(:br) +
          content_tag(:span, "Assigné le #{history.assigned_at.strftime('%d/%m/%Y %H:%M')}#{duration_text}", class: "text-gray-500")
        end
      end.join.html_safe

      content_tag :div, class: "member-history-details max-h-40 overflow-y-auto",
        data: { controller: "tooltip" } do
        history_items
      end
    end
  end
end

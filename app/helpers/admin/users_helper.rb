module Admin
  module UsersHelper
    # Badge de statut d'adhésion avec tooltip
    def membership_status_badge(person)
      if person.has_active_membership?
        current_membership = person.current_membership
        content_tag :span, 
          class: "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800 cursor-help",
          title: "Adhésion #{current_membership.membership_type.name} - Expire le #{current_membership.ended_at.strftime('%d/%m/%Y')}",
          data: { 
            controller: "tooltip",
            tooltip_content: "Adhésion #{current_membership.membership_type.name} - Expire le #{current_membership.ended_at.strftime('%d/%m/%Y')}"
          } do
          "✓ Actif"
        end
      elsif person.memberships.exists?
        last_membership = person.memberships.order(:created_at).last
        content_tag :span, 
          class: "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800 cursor-help",
          title: "Adhésion #{last_membership.membership_type.name} expirée le #{last_membership.ended_at.strftime('%d/%m/%Y')}",
          data: { 
            controller: "tooltip",
            tooltip_content: "Adhésion #{last_membership.membership_type.name} expirée le #{last_membership.ended_at.strftime('%d/%m/%Y')}"
          } do
          "⚠ Expiré"
        end
      else
        content_tag :span, 
          class: "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800",
          title: "Aucune adhésion" do
          "✗ Aucune"
        end
      end
    end

    # Badge de type d'adhésion
    def membership_type_badge(person)
      if person.has_active_membership?
        current_membership = person.current_membership
        type_class = case current_membership.membership_type.name.downcase
        when 'basique', 'basic'
          'bg-blue-100 text-blue-800'
        when 'cirque', 'circus'
          'bg-purple-100 text-purple-800'
        else
          'bg-gray-100 text-gray-800'
        end
        
        content_tag :span, 
          class: "membership-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{type_class}" do
          current_membership.membership_type.name
        end
      else
        content_tag :span, 
          class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800" do
          "Aucune"
        end
      end
    end

    # Badge de cotisations (séances restantes)
    def subscription_status_badge(person)
      active_books = person.book_of_entries.active
      
      if active_books.any?
        total_sessions = active_books.sum(&:sessions_remaining)
        content_tag :span, 
          class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-indigo-100 text-indigo-800 cursor-help",
          title: "#{total_sessions} séances restantes",
          data: { 
            controller: "tooltip",
            tooltip_content: "#{total_sessions} séances restantes"
          } do
          "#{total_sessions} séances"
        end
      else
        content_tag :span, 
          class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800" do
          "Aucune"
        end
      end
    end

    # Icône de compte web
    def web_account_icon(person)
      if person.user
        content_tag :svg, 
          class: "h-5 w-5 text-green-500 cursor-help",
          title: "Compte web actif (#{person.user.system_role.humanize})",
          fill: "none",
          stroke: "currentColor",
          viewBox: "0 0 24 24",
          data: { 
            controller: "tooltip",
            tooltip_content: "Compte web actif (#{person.user.system_role.humanize})"
          } do
          content_tag :path, "", 
            stroke_linecap: "round",
            stroke_linejoin: "round",
            stroke_width: "2",
            d: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
        end
      else
        content_tag :svg, 
          class: "h-5 w-5 text-gray-400 cursor-help",
          title: "Pas de compte web",
          fill: "none",
          stroke: "currentColor",
          viewBox: "0 0 24 24",
          data: { 
            controller: "tooltip",
            tooltip_content: "Pas de compte web"
          } do
          content_tag :path, "", 
            stroke_linecap: "round",
            stroke_linejoin: "round",
            stroke_width: "2",
            d: "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
        end
      end
    end

    # Actions contextuelles
    def contextual_actions(person)
      actions = []
      
      # Action "Voir" (toujours disponible)
      actions << link_to(
        content_tag(:svg, 
          content_tag(:path, "", 
            stroke_linecap: "round",
            stroke_linejoin: "round",
            stroke_width: "2",
            d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z"
          ) + content_tag(:path, "", 
            stroke_linecap: "round",
            stroke_linejoin: "round",
            stroke_width: "2",
            d: "M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
          ),
          class: "h-4 w-4",
          fill: "none",
          stroke: "currentColor",
          viewBox: "0 0 24 24"
        ),
        admin_user_path("person_#{person.id}"),
        class: "action-icon text-gray-600 hover:text-[#1F5C55] mr-2",
        title: "Voir la fiche",
        data: { turbo: false }
      )
      
      # Action "Créer Espace Utilisateur" (si pas de compte)
      unless person.user
        actions << link_to(
          content_tag(:svg, 
            content_tag(:path, "", 
              stroke_linecap: "round",
              stroke_linejoin: "round",
              stroke_width: "2",
              d: "M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"
            ),
            class: "h-4 w-4",
            fill: "none",
            stroke: "currentColor",
            viewBox: "0 0 24 24"
          ),
          new_admin_user_path(person_id: person.id),
          class: "action-icon text-green-600 hover:text-green-800 mr-2",
          title: "Créer un compte web",
          data: { turbo: false }
        )
      end
      
      # Actions d'adhésion
      if person.has_active_membership?
        current_membership = person.current_membership
        if current_membership.membership_type.name.downcase.include?('basic')
          # Upgrade vers Cirque
          actions << link_to(
            content_tag(:svg, 
              content_tag(:path, "", 
                stroke_linecap: "round",
                stroke_linejoin: "round",
                stroke_width: "2",
                d: "M7 11l5-5m0 0l5 5m-5-5v12"
              ),
              class: "h-4 w-4",
              fill: "none",
              stroke: "currentColor",
              viewBox: "0 0 24 24"
            ),
            "#", # TODO: Lien vers upgrade
            class: "action-icon text-purple-600 hover:text-purple-800 mr-2",
            title: "Upgrade vers Cirque"
          )
        end
        # Voir l'adhésion
        actions << link_to(
          content_tag(:svg, 
            content_tag(:path, "", 
              stroke_linecap: "round",
              stroke_linejoin: "round",
              stroke_width: "2",
              d: "M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2"
            ),
            class: "h-4 w-4",
            fill: "none",
            stroke: "currentColor",
            viewBox: "0 0 24 24"
          ),
          "#", # TODO: Lien vers détails adhésion
          class: "action-icon text-blue-600 hover:text-blue-800 mr-2",
          title: "Voir l'adhésion"
        )
      else
        # Ajouter une adhésion
        actions << link_to(
          content_tag(:svg, 
            content_tag(:path, "", 
              stroke_linecap: "round",
              stroke_linejoin: "round",
              stroke_width: "2",
              d: "M12 6v6m0 0v6m0-6h6m-6 0H6"
            ),
            class: "h-4 w-4",
            fill: "none",
            stroke: "currentColor",
            viewBox: "0 0 24 24"
          ),
          new_admin_membership_path(person_id: person.id),
          class: "action-icon text-green-600 hover:text-green-800 mr-2",
          title: "Ajouter une adhésion"
        )
      end
      
      # Actions de cotisation (si adhésion Cirque)
      if person.has_active_membership? && person.current_membership.membership_type.name.downcase.include?('cirque')
        actions << link_to(
          content_tag(:svg, 
            content_tag(:path, "", 
              stroke_linecap: "round",
              stroke_linejoin: "round",
              stroke_width: "2",
              d: "M15 5v2m0 4v2m0 4v2M5 5a2 2 0 00-2 2v3a2 2 0 110 4v3a2 2 0 002 2h14a2 2 0 002-2v-3a2 2 0 110-4V7a2 2 0 00-2-2H5z"
            ),
            class: "h-4 w-4",
            fill: "none",
            stroke: "currentColor",
            viewBox: "0 0 24 24"
          ),
          "#", # TODO: Lien vers ajout cotisation
          class: "action-icon text-indigo-600 hover:text-indigo-800 mr-2",
          title: "Ajouter une cotisation"
        )
      end
      
      content_tag :div, class: "flex items-center" do
        actions.join.html_safe
      end
    end

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
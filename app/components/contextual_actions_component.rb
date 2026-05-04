# frozen_string_literal: true

class ContextualActionsComponent < ViewComponent::Base
  def initialize(person:)
    @person = person
  end

  def actions
    @actions ||= build_actions
  end

  private

  attr_reader :person

  def build_actions
    actions = []

    # Action "Voir" (toujours disponible)
    actions << { type: :view, icon: :view_icon, url: "person_#{person.id}",
                 class: "action-icon text-gray-600 hover:text-[#1F5C55] mr-2",
                 title: "Voir la fiche", data: { turbo: false } }

    # Action "Créer Espace Utilisateur" (si pas de compte)
    unless person.user
      actions << { type: :create_user, icon: :create_user_icon, url: "new",
                   class: "action-icon text-green-600 hover:text-green-800 mr-2",
                   title: "Créer un compte web", data: { turbo: false } }
    end

    # Actions d'adhésion
    actions.concat(membership_actions_data)

    # Actions de cotisation (si adhésion Cirque)
    if person.has_active_membership? && person.current_membership.membership_type.name.downcase.include?("cirque")
      actions << { type: :contribution, icon: :contribution_icon, url: "#",
                   class: "action-icon text-indigo-600 hover:text-indigo-800 mr-2",
                   title: "Ajouter une cotisation" }
    end

    actions.compact
  end

  def membership_actions_data
    actions = []

    if person.has_active_membership?
      current_membership = person.current_membership

      if current_membership.membership_type.name.downcase.include?("basic")
        # Upgrade vers Cirque
        actions << { type: :upgrade, icon: :upgrade_icon, url: "#",
                     class: "action-icon text-purple-600 hover:text-purple-800 mr-2",
                     title: "Upgrade vers Cirque" }
      end

      # Voir l'adhésion
      actions << { type: :view_membership, icon: :membership_icon, url: "#",
                   class: "action-icon text-blue-600 hover:text-blue-800 mr-2",
                   title: "Voir l'adhésion" }
    else
      # Ajouter une adhésion
      actions << { type: :add_membership, icon: :add_icon, url: "membership",
                   class: "action-icon text-green-600 hover:text-green-800 mr-2",
                   title: "Ajouter une adhésion" }
    end

    actions
  end

  # Icônes SVG
  def view_icon
    content_tag(:svg,
                content_tag(:path, "",
                            stroke_linecap: "round",
                            stroke_linejoin: "round",
                            stroke_width: "2",
                            d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z") + content_tag(:path, "",
                                                                                 stroke_linecap: "round",
                                                                                 stroke_linejoin: "round",
                                                                                 stroke_width: "2",
                                                                                 d: "M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"),
                class: "h-4 w-4",
                fill: "none",
                stroke: "currentColor",
                viewBox: "0 0 24 24")
  end

  def create_user_icon
    content_tag(:svg,
                content_tag(:path, "",
                            stroke_linecap: "round",
                            stroke_linejoin: "round",
                            stroke_width: "2",
                            d: "M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"),
                class: "h-4 w-4",
                fill: "none",
                stroke: "currentColor",
                viewBox: "0 0 24 24")
  end

  def upgrade_icon
    content_tag(:svg,
                content_tag(:path, "",
                            stroke_linecap: "round",
                            stroke_linejoin: "round",
                            stroke_width: "2",
                            d: "M7 11l5-5m0 0l5 5m-5-5v12"),
                class: "h-4 w-4",
                fill: "none",
                stroke: "currentColor",
                viewBox: "0 0 24 24")
  end

  def membership_icon
    content_tag(:svg,
                content_tag(:path, "",
                            stroke_linecap: "round",
                            stroke_linejoin: "round",
                            stroke_width: "2",
                            d: "M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2"),
                class: "h-4 w-4",
                fill: "none",
                stroke: "currentColor",
                viewBox: "0 0 24 24")
  end

  def add_icon
    content_tag(:svg,
                content_tag(:path, "",
                            stroke_linecap: "round",
                            stroke_linejoin: "round",
                            stroke_width: "2",
                            d: "M12 6v6m0 0v6m0-6h6m-6 0H6"),
                class: "h-4 w-4",
                fill: "none",
                stroke: "currentColor",
                viewBox: "0 0 24 24")
  end

  def contribution_icon
    content_tag(:svg,
                content_tag(:path, "",
                            stroke_linecap: "round",
                            stroke_linejoin: "round",
                            stroke_width: "2",
                            d: "M15 5v2m0 4v2m0 4v2M5 5a2 2 0 00-2 2v3a2 2 0 110 4v3a2 2 0 002 2h14a2 2 0 002-2v-3a2 2 0 110-4V7a2 2 0 00-2-2H5z"),
                class: "h-4 w-4",
                fill: "none",
                stroke: "currentColor",
                viewBox: "0 0 24 24")
  end
end

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

    unless person.user
      actions << { icon: :create_user_icon,
                   url: helpers.create_web_account_admin_member_path(person),
                   class: "action-icon text-green-600 hover:text-green-800 mr-2",
                   title: "Créer un compte web",
                   data: { turbo_method: :post, turbo_confirm: "Créer un compte web pour #{person.full_name} ?" } }
    end

    actions.concat(membership_actions_data)

    actions.compact
  end

  def membership_actions_data
    actions = []

    unless person.has_active_membership?
      actions << { icon: :add_icon,
                   url: helpers.new_admin_membership_path(person_id: person.id),
                   class: "action-icon text-green-600 hover:text-green-800 mr-2",
                   title: "Ajouter une adhésion" }
    end

    actions
  end

  # Icônes SVG
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
end

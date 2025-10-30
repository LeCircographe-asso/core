class WebAccountIconComponent < ViewComponent::Base
  def initialize(person:)
    @person = person
  end

  def icon_class
    if person.user
      "h-5 w-5 text-green-500 cursor-help"
    else
      "h-5 w-5 text-gray-400 cursor-help"
    end
  end

  def icon_title
    if person.user
      "Compte web actif (#{person.user.system_role.humanize})"
    else
      "Pas de compte web"
    end
  end

  def tooltip_data
    {
      controller: "tooltip",
      "tooltip-content-value": icon_title
    }
  end

  def svg_path
    if person.user
      # Check circle icon
      "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
    else
      # X circle icon
      "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
    end
  end

  def has_user_account?
    person.user.present?
  end

  private

  attr_reader :person
end

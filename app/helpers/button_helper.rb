# frozen_string_literal: true

module ButtonHelper
  # Helper pour créer des boutons avec état désactivé
  def disabled_button(text, options = {})
    base_classes = "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium"

    if options[:disabled]
      disabled_classes = "text-gray-400 bg-gray-300 cursor-not-allowed"
      all_classes = "#{base_classes} #{disabled_classes}"

      content_tag :button, text,
                  class: all_classes,
                  disabled: true,
                  title: options[:disabled_reason] || "Fonctionnalité temporairement désactivée"
    else
      active_classes = options[:classes] || "text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
      all_classes = "#{base_classes} #{active_classes}"

      content_tag :button, text,
                  class: all_classes,
                  data: options[:data] || {},
                  onclick: options[:onclick]
    end
  end

  # Helper pour créer des liens avec état désactivé
  def disabled_link(text, url, options = {})
    base_classes = "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium"

    if options[:disabled]
      disabled_classes = "text-gray-400 bg-gray-300 cursor-not-allowed pointer-events-none"
      all_classes = "#{base_classes} #{disabled_classes}"

      content_tag :span, text,
                  class: all_classes,
                  title: options[:disabled_reason] || "Fonctionnalité temporairement désactivée"
    else
      active_classes = options[:classes] || "text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
      all_classes = "#{base_classes} #{active_classes}"

      link_to text, url,
              class: all_classes,
              data: options[:data] || {}
    end
  end

  # Helper pour wrapper n'importe quel élément avec état désactivé
  def with_disabled_state(element, disabled: false, reason: nil)
    if disabled
      content_tag :div,
                  class: "opacity-50 pointer-events-none relative",
                  title: reason || "Fonctionnalité temporairement désactivée" do
        element
      end
    else
      element
    end
  end
end

# frozen_string_literal: true

module Ui
  class DisabledButtonComponent < ViewComponent::Base
    def initialize(text:, disabled: false, disabled_reason: nil, **options)
      @text = text
      @disabled = disabled
      @disabled_reason = disabled_reason
      @options = options
    end

    private

    attr_reader :text, :disabled, :disabled_reason, :options

    def button_classes
      base_classes = "inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium"
      default_enabled_theme =
        "text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"

      if disabled
        inactive = "cursor-not-allowed pointer-events-none opacity-75"

        if options[:classes].present?
          "#{base_classes} #{options[:classes]} #{inactive}"
        else
          "#{base_classes} bg-gray-100 text-gray-500 border-gray-200 #{inactive}"
        end
      else
        "#{base_classes} #{options[:classes] || default_enabled_theme}"
      end
    end

    def button_attributes
      attrs = {
        class: button_classes,
        type: "button"
      }

      if disabled
        attrs.merge!(
          disabled: true,
          "aria-disabled": "true",
          title: disabled_reason || "Fonctionnalité temporairement désactivée",
          'data-tooltip': disabled_reason
        )
      else
        attrs.merge!(options[:data] || {})
        attrs[:onclick] = options[:onclick] if options[:onclick]
      end

      attrs
    end
  end
end

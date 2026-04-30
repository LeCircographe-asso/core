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
      base_classes = 'inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium'

      if disabled
        "#{base_classes} disabled-state disabled-state--button"
      else
        active_classes = options[:classes] || 'text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]'
        "#{base_classes} #{active_classes}"
      end
    end

    def button_attributes
      attrs = {
        class: button_classes,
        type: 'button'
      }

      if disabled
        attrs.merge!(
          disabled: true,
          title: disabled_reason || 'Fonctionnalité temporairement désactivée',
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

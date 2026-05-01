# frozen_string_literal: true

module Ui
  class DisabledButtonComponent < ViewComponent::Base
    def initialize(text:, disabled: false, disabled_reason: nil, hint: nil, hint_classes: nil, wrapper_classes: nil,
                   show_disabled_reason_below_md: false, additional_aria_describedby: nil, **options)
      @text = text
      @disabled = disabled
      @disabled_reason = disabled_reason
      @hint = hint
      @hint_classes = hint_classes
      @wrapper_classes = wrapper_classes
      @show_disabled_reason_below_md = show_disabled_reason_below_md
      @additional_aria_describedby = additional_aria_describedby
      @options = options
    end

    private

    attr_reader :text, :disabled, :disabled_reason, :hint, :hint_classes, :wrapper_classes, :options,
                :additional_aria_describedby

    def show_disabled_reason_below_md
      @show_disabled_reason_below_md
    end

    def reason_below_md?
      show_disabled_reason_below_md && disabled && disabled_reason.present?
    end

    def hint_dom_id
      @hint_dom_id ||= "disabled-btn-hint-#{object_id}"
    end

    def reason_below_md_dom_id
      @reason_below_md_dom_id ||= "disabled-btn-reason-below-#{object_id}"
    end

    def effective_hint_classes
      hint_classes.presence || "text-[11px] text-gray-500 leading-none max-w-fit whitespace-nowrap shrink-0"
    end

    def effective_wrapper_classes
      wrapper_classes.presence || "inline-flex flex-row flex-nowrap items-center gap-1"
    end

    def wrapper_classes_for_fragment
      if reason_below_md?
        wrapper_classes.presence || "flex flex-col w-full min-w-0 gap-1"
      elsif hint.present?
        effective_wrapper_classes
      end
    end

    def describedby_ids
      [].tap do |ids|
        ids << hint_dom_id if hint.present?
        ids << reason_below_md_dom_id if reason_below_md?
        ids << additional_aria_describedby if additional_aria_describedby.present?
      end.join(" ").presence
    end

    def button_classes
      base_classes = "inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium"
      default_enabled_theme =
        "text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"

      if disabled
        # No pointer-events-none: keeps native title tooltip and hover feedback usable.
        inactive = "cursor-not-allowed opacity-75"

        if options[:classes].present?
          # Do not prepend base_classes: its px/py/rounded utilities can override @layer
          # components (e.g. .btn-primary) in the cascade and shrink the control.
          "#{options[:classes]} #{inactive}"
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
        aria = { disabled: "true" }
        describedby = describedby_ids
        aria[:describedby] = describedby if describedby

        data = {}
        data[:tooltip] = disabled_reason if disabled_reason.present?

        attrs.merge!(
          disabled: true,
          aria: aria,
          title: disabled_reason || "Fonctionnalité temporairement désactivée",
          data: data
        )
      else
        attrs[:data] = options[:data] if options[:data].present?
        attrs[:onclick] = options[:onclick] if options[:onclick]
      end

      attrs
    end
  end
end

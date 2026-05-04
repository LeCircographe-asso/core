# frozen_string_literal: true

module RateKindable
  extend ActiveSupport::Concern

  RATE_KINDS = %w[standard reduced].freeze

  included do
    validates :rate_kind, presence: true, inclusion: { in: RATE_KINDS }
    scope :for_rate_kinds, ->(rate_kinds) { where(rate_kind: Array(rate_kinds)) }
  end

  def standard_rate?
    rate_kind == "standard"
  end

  def reduced_rate?
    rate_kind == "reduced"
  end

  def available_for?(person)
    person&.allows_rate_kind?(rate_kind) || false
  end

  def rate_kind_humanized
    self.class.humanize_rate_kind(rate_kind)
  end

  def rate_kind_badge_class
    reduced_rate? ? "bg-amber-100 text-amber-800" : "bg-slate-100 text-slate-800"
  end

  class_methods do
    def rate_kind_options
      RATE_KINDS.map { |kind| [ humanize_rate_kind(kind), kind ] }
    end

    def humanize_rate_kind(kind)
      case kind.to_s
      when "standard"
        "Tarif standard"
      when "reduced"
        "Tarif réduit"
      else
        kind.to_s.humanize
      end
    end
  end
end

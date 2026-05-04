# frozen_string_literal: true

module People
  class ContributionPayloadBuilder
    def self.call(contribution_formula, reference_date: Date.current)
      sessions_remaining = case contribution_formula.duration
      when "pack10"
                             contribution_formula.sessions_count || 10
      when "day"
                             1
      when "trimester", "annual"
                             nil
      else
                             contribution_formula.sessions_count || 1
      end

      expires_at = case contribution_formula.duration
      when "pack10"
                     nil
      when "day"
                     reference_date.end_of_day
      when "trimester"
                     reference_date + 90.days
      when "annual"
                     reference_date + 1.year
      else
                     contribution_formula.validity_days ? reference_date + contribution_formula.validity_days.days : nil
      end

      { sessions_remaining: sessions_remaining, expires_at: expires_at }
    end
  end
end

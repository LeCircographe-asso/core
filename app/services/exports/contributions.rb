# frozen_string_literal: true

module Exports
  class Contributions < Base
    export_version 1
    period_on Contribution, :purchased_at

    column(:contribution_id, &:id)
    person_columns(&:person)
    column(:formula) { |contribution| contribution.contribution_formula.name }
    column(:duration) { |contribution| contribution.contribution_formula.duration }
    column(:status, &:status)
    column(:purchased_at, &:purchased_at)
    column(:expires_at, &:expires_at)
    column(:sessions_remaining, &:sessions_remaining)
    column(:suspended_at, &:suspended_at)
    column(:suspended_reason, &:suspended_reason)

    private

    def scope
      Contribution.includes(:person, :contribution_formula)
    end
  end
end

# frozen_string_literal: true

module Exports
  class Memberships < Base
    export_version 1
    period_on Membership, :started_at

    column(:membership_id, &:id)
    person_columns(&:person)
    column(:membership_type) { |membership| membership.membership_type.name }
    column(:category) { |membership| membership.membership_type.category }
    column(:status, &:status)
    column(:started_at, &:started_at)
    column(:ended_at, &:ended_at)
    column(:first_joined_at, &:first_joined_at)
    column(:created_at, &:created_at)

    private

    def scope
      Membership.includes(:person, :membership_type)
    end
  end
end

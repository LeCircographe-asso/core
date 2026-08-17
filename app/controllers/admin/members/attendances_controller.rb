# frozen_string_literal: true

module Admin
  module Members
    class AttendancesController < BaseController
      before_action :set_person

      def new
        load_state
      end

      def create
        @result = AttendanceManagement::CheckInService.new(
          person_id: @person.id,
          contribution_id: params[:contribution_id].presence
        ).call

        load_state unless @result.success?

        respond_to(&:turbo_stream)
      end

      private

      def set_person
        member_id = params[:member_id]
        raise ActiveRecord::RecordNotFound, "member_id missing" if member_id.blank?

        @person = Person.find(member_id)
      end

      def load_state
        @already_present_today = @person.attendances.where(date: Date.current, event_id: nil).exists?
        @needs_membership = !@person.can_buy_contribution_formulas?
        @usable_contribution = @person.contributions.usable.detect(&:can_use?)
        @lender_query = params[:q].to_s.strip
        @lenders = lender_candidates
      end

      def lender_candidates
        PersonNameSearch.call(query: @lender_query, exclude_ids: [ @person.id ])
                        .joins(:contributions)
                        .merge(Contribution.pack10.active.where("contributions.sessions_remaining > 0"))
                        .distinct
                        .map { |candidate| [ candidate, candidate.contributions.pack10.active.where("sessions_remaining > 0").order(sessions_remaining: :desc).first ] }
      end
    end
  end
end

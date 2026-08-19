# frozen_string_literal: true

module AttendanceManagement
  class CheckInService < BaseService
    attribute :person_id, :integer
    attribute :contribution_id, :integer
    attribute :attendance_list_date, :date
    attribute :attendance_list_id, :integer

    validates :person_id, presence: true

    def call
      person = Person.find(person_id)
      contribution = find_contribution(person)

      if contribution && contribution.person_id != person.id && !contribution.lendable_to?(person)
        return failure("Ce carnet ne peut pas être prêté à cette personne : Pack10 actif requis avec des séances restantes, et le bénéficiaire doit avoir une adhésion Cirque active.")
      end

      list = find_or_create_attendance_list
      creator = AttendanceCreator.new(
        person_id: person.id,
        attendance_list_id: list.id,
        contribution_id: contribution&.id,
        date: list.start_date.to_date
      )

      creator.call
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue StandardError => e
      Rails.logger.error "[CheckInService] Error: #{e.message}"
      failure("Error during check-in: #{e.message}")
    end

    private

    def find_contribution(person)
      return Contribution.find(contribution_id) if contribution_id.present?

      person.contributions
            .active
            .joins(:contribution_formula)
            .where(contribution_formulas: { duration: %w[pack10 day trimester annual] })
            .usable
            .order("contribution_formulas.duration DESC")
            .first
    end

    def find_or_create_attendance_list
      return AttendanceList.find(attendance_list_id) if attendance_list_id.present?

      target_date = attendance_list_date || Date.current

      list = AttendanceList.where(list_type: :training)
                           .where(start_date: target_date.all_day)
                           .first
      return list if list

      result = AttendanceListManagement::DailyListGenerator.new(date: target_date).call
      # `result` est un OpenStruct de succès/échec (BaseService) : sur échec (ex. liste déjà
      # existante créée entre-temps), `.attendance_list` n'existe pas et vaudrait nil sans
      # ce garde-fou — mieux vaut remonter la vraie raison que planter plus loin sur `nil.id`.
      raise result.message unless result.success?

      result.attendance_list
    end
  end
end

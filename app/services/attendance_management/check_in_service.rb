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
    rescue => e
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
                           .where(start_date: target_date.beginning_of_day..target_date.end_of_day)
                           .first
      return list if list

      AttendanceListManagement::DailyListGenerator.new(date: target_date).call.attendance_list
    end
  end
end

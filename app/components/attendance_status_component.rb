class AttendanceStatusComponent < ViewComponent::Base
  def initialize(person:, date: Date.current)
    @person = person
    @date = date
  end

  def attendance
    @attendance ||= @person.attendances.find_by(date: @date)
  end

  def present?
    attendance.present?
  end

  def badge_class
    present? ? "bg-green-100 text-green-800" : "bg-gray-100 text-gray-800"
  end

  def icon_class
    present? ? "fas fa-check-circle text-green-600" : "fas fa-clock text-gray-400"
  end

  def status_text
    present? ? "Présent" : "Absent"
  end
end

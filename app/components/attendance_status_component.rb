# frozen_string_literal: true

class AttendanceStatusComponent < ViewComponent::Base
  def initialize(person:, date: Date.current)
    @person = person
    @date = date
  end

  def attendance
    return @attendance if defined?(@attendance)

    @attendance = @person.attendances.find_by(date: @date)
  end

  delegate :present?, to: :attendance

  def badge_class
    present? ? "bg-green-100 text-green-800" : "bg-gray-100 text-gray-800"
  end

  def icon_class
    present? ? "fas fa-check-circle text-green-600" : "fas fa-clock text-gray-400"
  end

  def status_text
    present? ? "Présent" : "Absent"
  end

  def tooltip_text
    if present?
      "Présence enregistrée aujourd'hui à #{attendance.created_at.strftime('%H:%M')}"
    else
      "Aucune présence enregistrée pour aujourd'hui (#{@date.strftime('%d/%m/%Y')})"
    end
  end

  def tooltip_data
    {
      controller: "tooltip",
      "tooltip-content-value": tooltip_text
    }
  end
end

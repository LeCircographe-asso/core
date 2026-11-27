# frozen_string_literal: true

module Exports
  class Attendances < Base
    export_version 1
    period_on Attendance, :date

    column(:attendance_id, &:id)
    column(:date, &:date)
    person_columns(&:person)
    column(:attendance_list_id, &:attendance_list_id)
    column(:list_name) { |attendance| attendance.attendance_list&.name }
    column(:list_type) { |attendance| attendance.attendance_list&.list_type }
    column(:contribution_id, &:contribution_id)
    column(:formula) { |attendance| attendance.contribution&.contribution_formula&.name }

    private

    def scope
      Attendance.includes(:person, :attendance_list, contribution: :contribution_formula)
    end
  end
end

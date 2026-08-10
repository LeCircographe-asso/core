# frozen_string_literal: true

require "rails_helper"

RSpec.describe AttendanceStatusComponent, type: :component do
  it "shows 'Présent' when the person has an attendance for the given date" do
    person = create(:person)
    create(:attendance, person: person, date: Date.current, event: nil)

    render_inline(described_class.new(person: person, date: Date.current))

    expect(rendered_content).to include("Présent")
  end

  it "shows 'Absent' when the person has no attendance for the given date" do
    person = create(:person)

    render_inline(described_class.new(person: person, date: Date.current))

    expect(rendered_content).to include("Absent")
  end
end

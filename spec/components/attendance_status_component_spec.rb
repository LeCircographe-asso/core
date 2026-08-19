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

  it "explains the absence in the tooltip rather than leaving it unqualified" do
    person = create(:person)

    render_inline(described_class.new(person: person, date: Date.current))

    expect(rendered_content).to include("data-controller=\"tooltip\"")
    expect(rendered_content).to include("Aucune présence enregistrée pour")
  end

  it "shows the check-in time in the tooltip when present" do
    person = create(:person)
    attendance = create(:attendance, person: person, date: Date.current, event: nil)

    render_inline(described_class.new(person: person, date: Date.current))

    expect(rendered_content).to include("Présence enregistrée")
    expect(rendered_content).to include(attendance.created_at.strftime("%H:%M"))
  end
end

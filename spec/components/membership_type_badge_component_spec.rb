# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipTypeBadgeComponent, type: :component do
  it "shows the simplified type name for an active membership" do
    person = create(:person)
    create(:membership, :circus_full, person: person)

    render_inline(described_class.new(person: person))

    expect(rendered_content).to include("Cirque")
  end

  it "shows 'Aucune' when the person has no active membership" do
    person = create(:person)

    render_inline(described_class.new(person: person))

    expect(rendered_content).to include("Aucune")
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Members::MemberInfoComponent, type: :component do
  it "shows the internal notes card when the person has notes" do
    person = create(:person, notes: "Allergique aux arachides, prévenir en cas de goûter partagé.")

    render_inline(described_class.new(user: nil, person: person))

    expect(page).to have_text("Notes internes")
    expect(page).to have_text("Allergique aux arachides")
  end

  it "hides the internal notes card when the person has no notes" do
    person = create(:person, notes: nil)

    render_inline(described_class.new(user: nil, person: person))

    expect(page).not_to have_text("Notes internes")
  end
end

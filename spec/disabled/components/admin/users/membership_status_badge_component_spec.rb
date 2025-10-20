require "rails_helper"

RSpec.describe Admin::Users::MembershipStatusBadgeComponent, type: :component do
  include ViewComponent::TestHelpers
  let(:person) { create(:person) }
  let(:membership_type) { create(:membership_type, category: :basic) }
  let(:active_membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }
  let(:expired_membership) { create(:membership, person: person, membership_type: membership_type, status: :expired) }

  describe "with active membership" do
    before { active_membership }

    it "renders active status badge" do
      render_inline(described_class.new(person: person))
      
      expect(page).to have_css('.status-badge', text: 'Actif')
      expect(page).to have_css('.bg-green-100.text-green-800')
    end

    it "includes tooltip data" do
      render_inline(described_class.new(person: person))
      
      expect(page).to have_css('span[title]')
      expect(page).to have_css('span[data-controller="tooltip"]')
    end
  end

  describe "with expired membership" do
    before { expired_membership }

    it "renders expired status badge" do
      render_inline(described_class.new(person: person))
      
      expect(page).to have_css('.status-badge', text: 'Expiré')
      expect(page).to have_css('.bg-yellow-100.text-yellow-800')
    end
  end

  describe "without membership" do
    it "renders no membership badge" do
      render_inline(described_class.new(person: person))
      
      expect(page).to have_css('.status-badge', text: 'Aucune')
      expect(page).to have_css('.bg-gray-100.text-gray-800')
    end

    it "does not include tooltip for no membership" do
      render_inline(described_class.new(person: person))
      
      expect(page).not_to have_css('[data-controller="tooltip"]')
    end
  end

  describe "badge classes" do
    it "applies correct CSS classes for active membership" do
      active_membership
      render_inline(described_class.new(person: person))
      
      badge = page.find('.status-badge')
      expect(badge[:class]).to include('px-2', 'inline-flex', 'text-xs', 'leading-5', 'font-semibold', 'rounded-full')
    end
  end
end

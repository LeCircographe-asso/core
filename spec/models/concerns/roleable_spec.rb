# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Roleable do
  describe '#can_offer_items?' do
    it 'is true for admin and super_admin' do
      expect(create(:user, :admin).can_offer_items?).to be(true)
      expect(create(:user, :super_admin).can_offer_items?).to be(true)
    end

    it 'is false for volunteer and web_visitor' do
      expect(create(:user, :volunteer).can_offer_items?).to be(false)
      expect(create(:user, system_role: :web_visitor).can_offer_items?).to be(false)
    end
  end
end

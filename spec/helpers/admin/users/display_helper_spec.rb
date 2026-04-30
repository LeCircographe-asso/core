# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::Users::DisplayHelper, type: :helper do
  describe '#format_member_number' do
    it 'formats member number correctly' do
      expect(helper.format_member_number(123)).to eq('#123')
    end

    it 'handles nil gracefully' do
      expect(helper.format_member_number(nil)).to eq('-')
    end

    it 'handles empty string' do
      expect(helper.format_member_number('')).to eq('-')
    end

    it 'handles zero' do
      expect(helper.format_member_number(0)).to eq('#0')
    end
  end

  describe '#format_full_name' do
    let(:person) { create(:person, first_name: 'John', last_name: 'Doe') }

    it 'formats full name correctly' do
      expect(helper.format_full_name(person)).to eq('John Doe')
    end

    it 'handles person with only first name' do
      person.first_name = 'John'
      person.last_name = nil
      expect(helper.format_full_name(person)).to eq('John')
    end

    it 'handles person with only last name' do
      person.first_name = nil
      person.last_name = 'Doe'
      expect(helper.format_full_name(person)).to eq('Doe')
    end

    it 'handles person with no names' do
      person.first_name = nil
      person.last_name = nil
      expect(helper.format_full_name(person)).to eq('Nom non renseigné')
    end
  end

  describe '#format_display_date' do
    let(:date) { Date.new(2025, 10, 20) }

    it 'formats date correctly' do
      expect(helper.format_display_date(date)).to eq('20/10/2025')
    end

    it 'handles nil date' do
      expect(helper.format_display_date(nil)).to eq('-')
    end

    it 'handles string date' do
      expect(helper.format_display_date('2025-10-20')).to eq('20/10/2025')
    end
  end

  describe '#format_currency' do
    it 'formats currency correctly' do
      expect(helper.format_currency(12.50)).to eq('€12,50')
    end

    it 'handles zero' do
      expect(helper.format_currency(0)).to eq('€0,00')
    end

    it 'handles nil' do
      expect(helper.format_currency(nil)).to eq('-')
    end

    it 'handles integer' do
      expect(helper.format_currency(10)).to eq('€10,00')
    end
  end
end

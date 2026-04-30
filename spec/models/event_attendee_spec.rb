# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventAttendee, type: :model do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:event) }
    it { should belong_to(:payment).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:event_id) }
  end

  describe 'creation' do
    it 'can be created with user and event' do
      attendee = EventAttendee.create!(user: user, event: event)
      expect(attendee).to be_persisted
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventInterest, type: :model do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:event) }
  end

  describe 'validations' do
    it 'allows a single like per account and event' do
      create(:event_interest, user: user, event: event)
      duplicate = build(:event_interest, user: user, event: event)

      expect(duplicate).not_to be_valid
    end

    it 'enforces the uniqueness at the database level too' do
      create(:event_interest, user: user, event: event)
      duplicate = build(:event_interest, user: user, event: event)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows liking several events the same day' do
      create(:event_interest, user: user, event: event)

      expect(build(:event_interest, user: user, event: create(:event))).to be_valid
    end
  end

  it 'never touches the daily training presence' do
    create(:attendance, person: user.person, date: Date.current)

    expect { create(:event_interest, user: user, event: event) }.not_to change(Attendance, :count)
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventInterest, type: :model do
  let(:person) { create(:person) }
  let(:event) { create(:event) }

  describe 'associations' do
    it { should belong_to(:person) }
    it { should belong_to(:event) }
  end

  describe 'validations' do
    it 'allows a single like per person and event' do
      create(:event_interest, person: person, event: event)
      duplicate = build(:event_interest, person: person, event: event)

      expect(duplicate).not_to be_valid
    end

    it 'enforces the uniqueness at the database level too' do
      create(:event_interest, person: person, event: event)
      duplicate = build(:event_interest, person: person, event: event)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows liking several events the same day' do
      create(:event_interest, person: person, event: event)

      expect(build(:event_interest, person: person, event: create(:event))).to be_valid
    end
  end

  it 'never touches the daily training presence' do
    create(:attendance, person: person, event: nil, date: Date.current)

    expect { create(:event_interest, person: person, event: event) }.not_to change(Attendance, :count)
    expect(person.attendances.find_by(date: Date.current).event_id).to be_nil
  end
end

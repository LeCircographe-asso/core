require 'rails_helper'

RSpec.describe Attendances::CheckIn, type: :service do
  let(:person) { create(:person) }
  let(:event) { create(:event) }
  let(:membership_type) { create(:membership_type, category: :circus_full) }
  let(:membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }

  describe '#call' do
    context 'with valid person and active membership' do
      let(:service) { described_class.new(person_id: person.id, date: Date.current) }

      before { membership } # Ensure membership exists

      it 'creates attendance successfully' do
        result = service.call

        expect(result.success?).to be true
        expect(result.attendance).to be_persisted
        expect(result.attendance.person).to eq(person)
        expect(result.attendance.date).to eq(Date.current)
      end

      it 'creates attendance with event when provided' do
        service_with_event = described_class.new(
          person_id: person.id, 
          event_id: event.id, 
          date: Date.current
        )
        result = service_with_event.call

        expect(result.success?).to be true
        expect(result.attendance.event).to eq(event)
      end
    end

    context 'when person is not found' do
      let(:service) { described_class.new(person_id: 999999, date: Date.current) }

      it 'fails with appropriate message' do
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to eq('Person not found')
      end
    end

    context 'when person already checked in today' do
      let(:service) { described_class.new(person_id: person.id, date: Date.current) }

      before do
        membership
        create(:attendance, person: person, date: Date.current)
      end

      it 'fails with appropriate message' do
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to eq('Already checked in today')
      end
    end

    context 'when person has no valid subscription' do
      let(:service) { described_class.new(person_id: person.id, date: Date.current) }

      it 'fails when no active membership' do
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to eq('No valid subscription')
      end

      it 'succeeds when person has a valid book of entry' do
        subscription_plan = create(:subscription_plan, duration: :pack10, sessions_count: 10)
        book_of_entry = create(:book_of_entry, 
          person: person, 
          subscription_plan: subscription_plan, 
          status: :active, 
          sessions_remaining: 5
        )

        service_with_book = described_class.new(
          person_id: person.id, 
          date: Date.current, 
          book_of_entry_id: book_of_entry.id
        )
        result = service_with_book.call

        expect(result.success?).to be true
      end
    end

    context 'with book of entry' do
      let(:subscription_plan) { create(:subscription_plan, duration: :pack10, sessions_count: 10) }
      let(:book_of_entry) { create(:book_of_entry, 
        person: person, 
        subscription_plan: subscription_plan, 
        status: :active, 
        sessions_remaining: 5
      ) }
      let(:service) { described_class.new(
        person_id: person.id, 
        date: Date.current, 
        book_of_entry_id: book_of_entry.id
      ) }

      it 'uses a session from the book of entry' do
        expect { service.call }.to change { book_of_entry.reload.sessions_remaining }.by(-1)
      end

      it 'links attendance to book of entry' do
        result = service.call

        expect(result.success?).to be true
        expect(result.attendance.book_of_entry).to eq(book_of_entry)
      end
    end

    context 'when date is not provided' do
      let(:service) { described_class.new(person_id: person.id) }

      before { membership }

      it 'defaults to current date' do
        result = service.call

        expect(result.success?).to be true
        expect(result.attendance.date).to eq(Date.current)
      end
    end
  end

  describe 'validations' do
    it 'validates presence of person_id' do
      service = described_class.new(date: Date.current)
      expect(service).not_to be_valid
    end

    it 'validates presence of date' do
      service = described_class.new(person_id: person.id)
      expect(service).not_to be_valid
    end

    it 'is valid with required attributes' do
      service = described_class.new(person_id: person.id, date: Date.current)
      expect(service).to be_valid
    end
  end
end

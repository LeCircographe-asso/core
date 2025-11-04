require 'rails_helper'

RSpec.describe AttendanceManagement::AttendanceCreator do
  let(:person) { create(:person) }
  let(:event) { create(:event) }

  describe "#call" do
    context "with valid attributes" do
      it "creates attendance successfully" do
        creator = described_class.new(
          person_id: person.id,
          event_id: event.id
        )
        
        result = creator.call
        
        expect(result.success?).to be true
        expect(result.attendance).to be_present
        expect(result.attendance.person).to eq(person)
        expect(result.attendance.event).to eq(event)
      end

      it "sets date to current date if not provided" do
        creator = described_class.new(
          person_id: person.id,
          event_id: event.id
        )
        
        result = creator.call
        
        expect(result.attendance.date).to eq(Date.current)
      end

      it "uses provided date" do
        custom_date = Date.current - 1.day
        
        creator = described_class.new(
          person_id: person.id,
          event_id: event.id,
          date: custom_date
        )
        
        result = creator.call
        
        expect(result.attendance.date).to eq(custom_date)
      end
    end

    context "with invalid attributes" do
      it "returns failure when person_id is missing" do
        creator = described_class.new(event_id: event.id)
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Invalid data")
      end

      it "returns failure when person doesn't exist" do
        creator = described_class.new(
          person_id: 99999,
          event_id: event.id
        )
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("not found")
      end
    end

    context "with validation errors" do
      it "returns failure when duplicate attendance exists" do
        create(:attendance, person: person, event: event)
        
        creator = described_class.new(
          person_id: person.id,
          event_id: event.id
        )
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Validation error")
      end
    end

    context "with book_of_entry" do
      let(:circus_membership_type) { create(:membership_type, category: :circus) }
      let(:pack10_plan) { create(:subscription_plan, :pack10) }
      let(:attendance_list) { create(:attendance_list) }
      let!(:book_of_entry) do
        # Ensure person has active circus membership (required for can_use?)
        person.current_membership || create(:membership, person: person, membership_type: circus_membership_type, status: :active)
        create(:book_of_entry, person: person, subscription_plan: pack10_plan, sessions_remaining: 5)
      end
      
      it "decrements book_of_entry sessions when attendance_list is present" do
        initial_sessions = book_of_entry.sessions_remaining
        
        creator = described_class.new(
          person_id: person.id,
          book_of_entry_id: book_of_entry.id,
          attendance_list_id: attendance_list.id # Needed to trigger decrement callback
        )
        
        result = creator.call
        
        expect(result.success?).to be true
        expect(book_of_entry.reload.sessions_remaining).to eq(initial_sessions - 1)
      end
    end

    context "instrumentation" do
      it "fires attendance.created notification" do
        expect {
          creator = described_class.new(
            person_id: person.id,
            event_id: event.id
          )
          creator.call
        }.to instrument("attendance.created")
      end
    end
  end
end


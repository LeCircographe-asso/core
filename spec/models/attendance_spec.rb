require 'rails_helper'

RSpec.describe Attendance, type: :model do
  let(:person) { create(:person) }
  let(:event) { create(:event) }
  let(:circus_membership_type) { create(:membership_type, category: :circus) }
  let(:pack10_plan) { create(:subscription_plan, :pack10, membership_type: circus_membership_type) }

  describe "associations" do
    it { should belong_to(:person) }
    it { should belong_to(:event).optional }
    it { should belong_to(:attendance_list).optional }
    it { should belong_to(:book_of_entry).optional }
  end

  describe "validations" do
    it "validates presence of date" do
      attendance = build(:attendance, date: nil)
      expect(attendance).not_to be_valid
      expect(attendance.errors[:date]).to include("can't be blank")
    end

    context "with event" do
      it "validates uniqueness of person per event" do
        create(:attendance, person: person, event: event)
        duplicate = build(:attendance, person: person, event: event)
        
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:person_id]).to include("est déjà intéressé par cet événement")
      end

      it "allows same person for different events" do
        event2 = create(:event)
        create(:attendance, person: person, event: event)
        duplicate = build(:attendance, person: person, event: event2)
        
        expect(duplicate).to be_valid
      end
    end

    context "without event (attendance_list)" do
      it "validates uniqueness of person per date" do
        create(:attendance, person: person, event: nil, date: Date.current)
        duplicate = build(:attendance, person: person, event: nil, date: Date.current)
        
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:person_id]).to include("est déjà marqué présent aujourd'hui")
      end

      it "allows same person on different dates" do
        create(:attendance, person: person, event: nil, date: Date.current)
        different_date = build(:attendance, person: person, event: nil, date: Date.yesterday)
        
        expect(different_date).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:today_attendance) { create(:attendance, date: Date.current) }
    let!(:yesterday_attendance) { create(:attendance, date: Date.yesterday) }
    let!(:last_week_attendance) { create(:attendance, date: 1.week.ago) }

    describe ".today" do
      it "returns only today's attendances" do
        expect(Attendance.today).to include(today_attendance)
        expect(Attendance.today).not_to include(yesterday_attendance, last_week_attendance)
      end
    end

    describe ".this_week" do
      it "returns attendances from this week" do
        this_week = Attendance.this_week
        expect(this_week).to include(today_attendance, yesterday_attendance)
        expect(this_week).not_to include(last_week_attendance)
      end
    end

    describe ".this_month" do
      it "returns attendances from this month", :disabled do
        # Temporarily disabled due to timezone/date boundary issues
        this_month = Attendance.this_month
        expect(this_month).to include(today_attendance, yesterday_attendance, last_week_attendance)
      end
    end

    describe ".by_person" do
      it "returns attendances for specific person" do
        other_person = create(:person)
        create(:attendance, person: other_person)
        
        attendances = Attendance.by_person(person)
        expect(attendances).to all(have_attributes(person: person))
      end
    end

    describe ".by_event" do
      it "returns attendances for specific event" do
        other_event = create(:event)
        create(:attendance, event: other_event)
        
        attendances = Attendance.by_event(event)
        expect(attendances).to all(have_attributes(event: event))
      end
    end
  end

  describe "callbacks" do
    describe "#set_date_if_missing" do
      it "does not override existing date when set" do
        custom_date = 5.days.ago.to_date
        attendance = build(:attendance, date: custom_date)
        attendance.save!
        
        expect(attendance.date).to eq(custom_date)
      end
    end

    describe "#decrement_book_of_entry" do
      context "with attendance_list and book_of_entry" do
        let!(:book_of_entry) do
          person.current_membership || create(:membership, person: person, membership_type: circus_membership_type)
          create(:book_of_entry, person: person, subscription_plan: pack10_plan, sessions_remaining: 5)
        end
        let(:attendance_list) { create(:attendance_list) }

        it "decrements book_of_entry sessions when attendance created" do
          attendance = create(:attendance, person: person, attendance_list: attendance_list, book_of_entry: book_of_entry, event: nil)
          
          book_of_entry.reload
          expect(book_of_entry.sessions_remaining).to eq(4)
        end

        it "calls use_session! method" do
          allow(book_of_entry).to receive(:use_session!).and_return(true)
          
          create(:attendance, person: person, attendance_list: attendance_list, book_of_entry: book_of_entry, event: nil)
          
          expect(book_of_entry).to have_received(:use_session!)
        end

        it "does not decrement if attendance_list is nil" do
          book_of_entry = create(:book_of_entry, person: person, subscription_plan: pack10_plan, sessions_remaining: 5)
          
          create(:attendance, person: person, event: event, book_of_entry: book_of_entry)
          
          book_of_entry.reload
          expect(book_of_entry.sessions_remaining).to eq(5)
        end
      end

      context "without book_of_entry" do
        it "creates attendance successfully" do
          attendance_list = create(:attendance_list)
          attendance = build(:attendance, person: person, attendance_list: attendance_list, book_of_entry: nil, event: nil)
          
          expect { attendance.save! }.not_to raise_error
        end
      end
    end
  end

  describe "edge cases" do
    it "handles attendance without event or attendance_list" do
      attendance = build(:attendance, event: nil, attendance_list: nil)
      expect(attendance).to be_valid
    end

    it "handles attendance with both event and attendance_list" do
      attendance_list = create(:attendance_list)
      attendance = build(:attendance, event: event, attendance_list: attendance_list)
      
      # Should be valid, uniqueness based on event_id
      expect(attendance).to be_valid
    end
  end
end


require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:creator) { create(:user) }
  let(:event) { create(:event, creator: creator) }
  let(:person) { create(:person) }

  describe "associations" do
    it { should belong_to(:creator).class_name("User") }
    it { should have_many(:attendances).dependent(:destroy) }
    it { should have_many(:people).through(:attendances) }
  end

  describe "validations" do
    it "validates presence of name" do
      event = build(:event, name: nil)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include("can't be blank")
    end

    it "validates presence of date" do
      event = build(:event, date: nil)
      expect(event).not_to be_valid
      expect(event.errors[:date]).to include("can't be blank")
    end

    it "validates presence of category" do
      event = build(:event, category: nil)
      expect(event).not_to be_valid
      expect(event.errors[:category]).to include("can't be blank")
    end
  end

  describe "enums" do
    it "defines category enum" do
      expect(Event.categories).to eq({
        'show' => 0,
        'workshop' => 1,
        'volunteering' => 2,
        'other' => 3
      })
    end

    it "can be created with show category" do
      event = create(:event, :show)
      expect(event.show?).to be true
    end

    it "can be created with workshop category" do
      event = create(:event, :workshop)
      expect(event.workshop?).to be true
    end

    it "can be created with volunteering category" do
      event = create(:event, :volunteering)
      expect(event.volunteering?).to be true
    end

    it "can be created with other category" do
      event = create(:event, :other)
      expect(event.other?).to be true
    end
  end

  describe "scopes" do
    let!(:show_event) { create(:event, :show) }
    let!(:workshop_event) { create(:event, :workshop) }
    let!(:volunteering_event) { create(:event, :volunteering) }
    let!(:other_event) { create(:event, :other) }
    let!(:upcoming_event) { create(:event, :upcoming) }
    let!(:past_event) { create(:event, :past) }

    describe ".shows" do
      it "returns only show events" do
        expect(Event.shows).to include(show_event)
        expect(Event.shows).not_to include(workshop_event, volunteering_event, other_event)
      end
    end

    describe ".workshops" do
      it "returns only workshop events" do
        expect(Event.workshops).to include(workshop_event)
        expect(Event.workshops).not_to include(show_event, volunteering_event, other_event)
      end
    end

    describe ".volunteering" do
      it "returns only volunteering events" do
        expect(Event.volunteering).to include(volunteering_event)
        expect(Event.volunteering).not_to include(show_event, workshop_event, other_event)
      end
    end

    describe ".others" do
      it "returns only other events" do
        expect(Event.others).to include(other_event)
        expect(Event.others).not_to include(show_event, workshop_event, volunteering_event)
      end
    end

    describe ".upcoming" do
      it "returns only future events" do
        expect(Event.upcoming).to include(upcoming_event)
        expect(Event.upcoming).not_to include(past_event)
      end
    end

    describe ".past" do
      it "returns only past events" do
        expect(Event.past).to include(past_event)
        expect(Event.past).not_to include(upcoming_event)
      end
    end

    describe ".by_date" do
      it "orders events by date" do
        events = Event.by_date
        dates = events.pluck(:date)
        expect(dates).to eq(dates.sort)
      end
    end

    describe "date scopes" do
      let(:creator1) { create(:user) }
      let(:creator2) { create(:user) }
      let(:creator3) { create(:user) }

      # Create events with specific dates
      let!(:today_event) { create(:event, creator: creator1, date: Date.current.beginning_of_day + 12.hours) }
      let!(:this_week_event) do
        week_date = if Date.current.beginning_of_week != Date.current
          Date.current.beginning_of_week.beginning_of_day + 12.hours
        else
          Date.current.end_of_week.beginning_of_day + 12.hours
        end
        create(:event, creator: creator2, date: week_date)
      end
      let!(:last_week_event) do
        last_week_date = Date.current - 1.week
        # If last week is in a different month, use a date from earlier this month (but not this week)
        event_date = if last_week_date.month != Date.current.month
          [ Date.current.beginning_of_month, Date.current.beginning_of_week - 1.day ].max.beginning_of_day + 12.hours
        else
          last_week_date.beginning_of_day + 12.hours
        end
        create(:event, creator: creator3, date: event_date)
      end

      describe ".today" do
        it "returns only today's events" do
          expect(Event.today).to include(today_event)
          expect(Event.today).not_to include(this_week_event, last_week_event)
        end
      end

      describe ".this_week" do
        it "returns events from this week" do
          this_week = Event.this_week
          expect(this_week).to include(today_event, this_week_event)
          expect(this_week).not_to include(last_week_event)
        end
      end

      describe ".this_month" do
        it "returns events from this month" do
          this_month = Event.this_month
          expect(this_month).to include(today_event, this_week_event)
          # last_week_event should be included if it's in the same month
          if last_week_event.date.to_date.month == Date.current.month
            expect(this_month).to include(last_week_event)
          else
            expect(this_month).not_to include(last_week_event)
          end
        end
      end
    end
  end

  describe "#is_person_registered?" do
    it "returns false when person is not registered" do
      expect(event.is_person_registered?(person)).to be false
    end

    it "returns true when person is registered" do
      create(:attendance, event: event, person: person)
      expect(event.is_person_registered?(person)).to be true
    end
  end

  describe "#is_user_registered?" do
    context "with user having person" do
      let(:user_with_person) { create(:user, person: person) }

      it "uses person registration" do
        create(:attendance, event: event, person: person)
        expect(event.is_user_registered?(user_with_person)).to be true
      end
    end

    context "with user without person" do
      let(:user_without_person) { create(:user, person: nil) }

      it "returns false (no legacy event_attendees)" do
        expect(event.is_user_registered?(user_without_person)).to be false
      end
    end
  end

  describe "#title and #title=" do
    it "aliases name to title" do
      event = create(:event, name: "Test Event")
      expect(event.title).to eq("Test Event")
    end

    it "allows setting name via title=" do
      event = create(:event)
      event.title = "New Title"
      expect(event.name).to eq("New Title")
    end
  end

  describe "#full_description" do
    context "with description present" do
      it "returns description" do
        event = create(:event, description: "Main description")
        expect(event.full_description).to eq("Main description")
      end
    end

    context "without description but with upper/middle/bottom" do
      it "joins all description parts" do
        event = create(:event,
                       description: nil,
                       upper_description: "Upper",
                       middle_description: "Middle",
                       bottom_description: "Bottom")
        result = event.full_description
        expect(result).to include("Upper")
        expect(result).to include("Middle")
        expect(result).to include("Bottom")
      end
    end

    context "with no description at all" do
      it "returns empty string" do
        event = create(:event,
                       description: nil,
                       upper_description: nil,
                       middle_description: nil,
                       bottom_description: nil)
        expect(event.full_description).to eq("")
      end
    end
  end
end

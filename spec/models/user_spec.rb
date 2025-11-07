require 'rails_helper'

RSpec.describe User, type: :model do
  describe "basic functionality" do
    it "can be created" do
      user = User.new(email: "test@example.com")
      expect(user).to be_present
    end
  end

  describe "date scopes (using created_at via Dateable)" do
    let!(:today_user) { create(:user, created_at: Date.current.beginning_of_day + 12.hours) }
    let!(:this_week_user) do
      week_date = if Date.current.beginning_of_week != Date.current
        Date.current.beginning_of_week.beginning_of_day + 12.hours
      else
        Date.current.end_of_week.beginning_of_day + 12.hours
      end
      create(:user, created_at: week_date)
    end
    let!(:last_week_user) do
      last_week_date = Date.current - 1.week
      # If last week is in a different month, use a date from earlier this month (but not this week)
      user_date = if last_week_date.month != Date.current.month
        [ Date.current.beginning_of_month, Date.current.beginning_of_week - 1.day ].max.beginning_of_day + 12.hours
      else
        last_week_date.beginning_of_day + 12.hours
      end
      create(:user, created_at: user_date)
    end

    describe ".today" do
      it "returns only users created today" do
        expect(User.today).to include(today_user)
        expect(User.today).not_to include(this_week_user, last_week_user)
      end
    end

    describe ".this_week" do
      it "returns users created this week" do
        this_week = User.this_week
        expect(this_week).to include(today_user, this_week_user)
        expect(this_week).not_to include(last_week_user)
      end
    end

    describe ".this_month" do
      it "returns users created this month" do
        this_month = User.this_month
        expect(this_month).to include(today_user, this_week_user)
        # last_week_user should be included if it's in the same month
        if last_week_user.created_at.to_date.month == Date.current.month
          expect(this_month).to include(last_week_user)
        else
          expect(this_month).not_to include(last_week_user)
        end
      end
    end
  end

  describe "Dateable instance methods" do
    let(:user) { create(:user, created_at: Date.current.beginning_of_day + 14.hours) }

    describe "#today?" do
      it "returns true for user created today" do
        expect(user.today?(:created_at)).to be true
      end

      it "returns false for user created yesterday" do
        old_user = create(:user, created_at: Date.yesterday.beginning_of_day + 14.hours)
        expect(old_user.today?(:created_at)).to be false
      end
    end

    describe "#this_week?" do
      it "returns true for user created this week" do
        expect(user.this_week?(:created_at)).to be true
      end
    end

    describe "#this_month?" do
      it "returns true for user created this month" do
        expect(user.this_month?(:created_at)).to be true
      end
    end

    describe "#formatted_date" do
      it "formats created_at date" do
        formatted = user.formatted_date(:created_at)
        expect(formatted).to match(/\d{2}\/\d{2}\/\d{4}/)
      end
    end
  end
end

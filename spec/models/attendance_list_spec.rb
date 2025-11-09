require 'rails_helper'

RSpec.describe AttendanceList, type: :model do
  describe "associations" do
    it { should have_many(:attendances).dependent(:destroy) }
    # Note: has_many :users through :attendances doesn't exist in model
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }

    it "validates end_date is after start_date" do
      list = build(:attendance_list, start_date: Date.current, end_date: Date.current - 1.day)
      expect(list).not_to be_valid
      expect(list.errors[:end_date]).to include("doit être après la date de début")
    end

    it "is valid when end_date is after start_date" do
      list = build(:attendance_list, start_date: Date.current, end_date: Date.current + 1.day)
      expect(list).to be_valid
    end
  end

  describe "enums" do
    it { should define_enum_for(:list_type).with_values(training: 0, event: 1, meeting: 2) }
    it { should define_enum_for(:status).with_values(open: 0, close: 1, archived: 2) }

    it "has training as default list_type" do
      list = AttendanceList.new
      expect(list.list_type).to eq("training")
    end

    it "has open as default status" do
      list = AttendanceList.new
      expect(list.status).to eq("open")
    end
  end

  describe "callbacks" do
    describe "#set_default_name" do
      context "when list_type is training" do
        it "sets default name based on start_date" do
          list = build(:attendance_list, name: nil, list_type: :training, start_date: Date.parse("2024-03-15"))
          list.valid?
          expect(list.name).to eq("Registre de présence 15/03/2024")
        end
      end

      context "when list_type is event" do
        it "sets default name based on start_date" do
          list = build(:attendance_list, name: nil, list_type: :event, start_date: Date.parse("2024-05-20"))
          list.valid?
          expect(list.name).to eq("Événement du 20/05/2024")
        end
      end

      context "when list_type is meeting" do
        it "sets default name based on start_date" do
          list = build(:attendance_list, name: nil, list_type: :meeting, start_date: Date.parse("2024-06-10"))
          list.valid?
          expect(list.name).to eq("Réunion du 10/06/2024")
        end
      end

      it "does not override existing name" do
        list = build(:attendance_list, name: "Custom Name", start_date: Date.current)
        list.valid?
        expect(list.name).to eq("Custom Name")
      end
    end
  end

  describe "status methods" do
    it "responds to open?, close?, archived?" do
      list = create(:attendance_list)
      expect(list.open?).to be true
      list.update!(status: :close)
      expect(list.close?).to be true
      list.update!(status: :archived)
      expect(list.archived?).to be true
    end
  end

  describe "list_type methods" do
    it "responds to training?, event?, meeting?" do
      list = create(:attendance_list, list_type: :training)
      expect(list.training?).to be true
      list.update!(list_type: :event)
      expect(list.event?).to be true
      list.update!(list_type: :meeting)
      expect(list.meeting?).to be true
    end
  end

  describe "Statusable concern methods" do
    let(:list) { create(:attendance_list, status: :open) }

    describe "#status_humanized" do
      it "returns humanized status" do
        # Statusable uses .humanize as fallback for unknown statuses
        expect(list.status_humanized).to be_present
      end

      it "returns humanized status for closed" do
        closed_list = create(:attendance_list, status: :close)
        expect(closed_list.status_humanized).to be_present
      end

      it "returns humanized status for archived" do
        archived_list = create(:attendance_list, status: :archived)
        expect(archived_list.status_humanized).to be_present
      end
    end

    describe "#status_badge_class" do
      it "returns badge class for open status" do
        expect(list.status_badge_class).to be_present
      end
    end
  end

  describe "Dateable concern methods" do
    let(:list) { create(:attendance_list, start_date: Date.current.beginning_of_day + 12.hours, end_date: Date.current + 1.day) }

    describe "#formatted_date" do
      it "formats start_date" do
        formatted = list.formatted_date(:start_date)
        expect(formatted).to match(/\d{2}\/\d{2}\/\d{4}/)
      end

      it "formats end_date" do
        formatted = list.formatted_date(:end_date)
        expect(formatted).to match(/\d{2}\/\d{2}\/\d{4}/)
      end
    end

    describe "#formatted_datetime" do
      it "formats start_date datetime" do
        formatted = list.formatted_datetime(:start_date)
        expect(formatted).to match(/\d{2}\/\d{2}\/\d{4} à \d{2}:\d{2}/)
      end
    end

    describe "#today?" do
      it "returns true for list starting today" do
        expect(list.today?(:start_date)).to be true
      end

      it "returns false for list starting yesterday" do
        old_list = create(:attendance_list, start_date: Date.yesterday.beginning_of_day + 12.hours)
        expect(old_list.today?(:start_date)).to be false
      end
    end

    describe "#this_week?" do
      it "returns true for list starting this week" do
        expect(list.this_week?(:start_date)).to be true
      end
    end

    describe "#this_month?" do
      it "returns true for list starting this month" do
        expect(list.this_month?(:start_date)).to be true
      end
    end

    describe "#duration_days" do
      it "calculates duration between start_date and end_date" do
        expect(list.duration_days(:start_date, :end_date)).to eq(1)
      end
    end
  end
end

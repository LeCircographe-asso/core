require 'rails_helper'

RSpec.describe EventManagement::EventDeleter do
  let(:admin) { create(:user, :admin) }

  describe '#call' do
    context 'when event has no attendees' do
      let!(:event) { create(:event) }

      it 'destroys the event and returns success' do
        deleter = described_class.new(
          event_id: event.id,
          deleted_by_id: admin.id,
          reason: 'Cleanup'
        )

        result = nil

        expect do
          result = deleter.call
        end.to change(Event, :count).by(-1)

        expect(result.success?).to be(true)
        expect(result.message).to eq('Event deleted successfully')
      end
    end

    context 'when event has attendees' do
      let!(:event) { create(:event) }
      let!(:person) { create(:person) }
      let!(:attendance) { create(:attendance, event: event, person: person) }

      it 'destroys the event and its interest links' do
        deleter = described_class.new(
          event_id: event.id,
          deleted_by_id: admin.id,
          reason: 'Cleanup'
        )

        result = nil

        expect do
          result = deleter.call
        end.to change(Event, :count).by(-1)

        expect(result.success?).to be(true)
        expect(result.message).to eq('Event deleted successfully')
        expect(Attendance.exists?(attendance.id)).to be(false)
      end
    end
  end
end

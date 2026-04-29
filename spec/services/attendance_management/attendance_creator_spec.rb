require 'rails_helper'

RSpec.describe AttendanceManagement::AttendanceCreator do
  let(:person) { create(:person) }
  let(:event) { create(:event) }

  describe '#call' do
    context 'with valid attributes' do
      it 'creates attendance successfully' do
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

      it 'sets date to current date if not provided' do
        creator = described_class.new(
          person_id: person.id,
          event_id: event.id
        )

        result = creator.call

        expect(result.attendance.date).to eq(Date.current)
      end

      it 'uses provided date' do
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

    context 'with invalid attributes' do
      it 'returns failure when person_id is missing' do
        creator = described_class.new(event_id: event.id)

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end

      it "returns failure when person doesn't exist" do
        creator = described_class.new(
          person_id: 99_999,
          event_id: event.id
        )

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include('not found')
      end
    end

    context 'with validation errors' do
      it 'returns failure when duplicate attendance exists' do
        create(:attendance, person: person, event: event)

        creator = described_class.new(
          person_id: person.id,
          event_id: event.id
        )

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include('Validation error')
      end
    end

    context 'with contribution' do
      let(:circus_membership_type) { create(:membership_type, category: :circus) }
      let(:pack10_plan) { create(:contribution_formula, :pack10) }
      let(:attendance_list) { create(:attendance_list) }
      let!(:contribution) do
        # Ensure person has active circus membership (required for can_use?)
        person.current_membership || create(:membership, person: person, membership_type: circus_membership_type, status: :active)
        create(:contribution, person: person, contribution_formula: pack10_plan, sessions_remaining: 5)
      end

      it 'decrements contribution sessions when attendance_list is present' do
        initial_sessions = contribution.sessions_remaining

        creator = described_class.new(
          person_id: person.id,
          contribution_id: contribution.id,
          attendance_list_id: attendance_list.id # Needed to trigger decrement callback
        )

        result = creator.call

        expect(result.success?).to be true
        expect(contribution.reload.sessions_remaining).to eq(initial_sessions - 1)
      end
    end

    context 'with day pass' do
      let(:circus_membership_type) { create(:membership_type, category: :circus) }
      let(:day_plan) { create(:contribution_formula, :day, membership_type: circus_membership_type) }
      let(:circus_person) { create(:person, :with_circus_membership) }
      let(:attendance_list) { create(:attendance_list) }
      let!(:day_book) do
        create(:contribution, person: circus_person, contribution_formula: day_plan, sessions_remaining: 1, expires_at: Date.current.end_of_day)
      end

      it 'consumes the day session and records attendance' do
        creator = described_class.new(
          person_id: circus_person.id,
          attendance_list_id: attendance_list.id,
          contribution_id: day_book.id
        )

        result = creator.call

        expect(result.success?).to be true
        expect(result.attendance.attendance_list).to eq(attendance_list)
        expect(day_book.reload.sessions_remaining).to eq(0)
        expect(day_book.status).to eq('consumed')
      end
    end

    context 'with trimester subscription' do
      let(:circus_membership_type) { create(:membership_type, category: :circus) }
      let(:trimester_plan) { create(:contribution_formula, :trimester, membership_type: circus_membership_type) }
      let(:circus_person) { create(:person, :with_circus_membership) }
      let(:attendance_list) { create(:attendance_list) }
      let!(:trimester_book) do
        create(:contribution, person: circus_person, contribution_formula: trimester_plan, sessions_remaining: nil, expires_at: 3.months.from_now)
      end

      it 'records attendance without altering unlimited access' do
        creator = described_class.new(
          person_id: circus_person.id,
          attendance_list_id: attendance_list.id,
          contribution_id: trimester_book.id
        )

        result = creator.call

        expect(result.success?).to be true
        expect(trimester_book.reload.sessions_remaining).to be_nil
        expect(trimester_book.status).to eq('active')
      end
    end

    context 'with annual subscription' do
      let(:circus_membership_type) { create(:membership_type, category: :circus) }
      let(:annual_plan) { create(:contribution_formula, :annual, membership_type: circus_membership_type) }
      let(:circus_person) { create(:person, :with_circus_membership) }
      let(:attendance_list) { create(:attendance_list) }
      let!(:annual_book) do
        create(:contribution, person: circus_person, contribution_formula: annual_plan, sessions_remaining: nil, expires_at: 1.year.from_now)
      end

      it 'keeps annual book active after attendance' do
        creator = described_class.new(
          person_id: circus_person.id,
          attendance_list_id: attendance_list.id,
          contribution_id: annual_book.id
        )

        result = creator.call

        expect(result.success?).to be true
        expect(annual_book.reload.status).to eq('active')
      end
    end

    context 'refund scenario' do
      let(:circus_membership_type) { create(:membership_type, category: :circus) }
      let(:pack10_plan) { create(:contribution_formula, :pack10, membership_type: circus_membership_type) }
      let(:circus_person) { create(:person, :with_circus_membership) }
      let(:attendance_list) { create(:attendance_list) }
      let!(:pack_book) do
        create(:contribution, person: circus_person, contribution_formula: pack10_plan, sessions_remaining: 2)
      end

      it 'allows destroying attendance and re-crediting sessions manually' do
        creator = described_class.new(
          person_id: circus_person.id,
          attendance_list_id: attendance_list.id,
          contribution_id: pack_book.id
        )

        result = creator.call
        expect(result.success?).to be true
        expect(pack_book.reload.sessions_remaining).to eq(1)

        expect { result.attendance.destroy }.to change { Attendance.count }.by(-1)

        pack_book.update!(sessions_remaining: 2, status: :active)

        second_result = described_class.new(
          person_id: circus_person.id,
          attendance_list_id: attendance_list.id,
          contribution_id: pack_book.id
        ).call

        expect(second_result.success?).to be true
        expect(pack_book.reload.sessions_remaining).to eq(1)
      end
    end

    context 'instrumentation' do
      it 'fires attendance.created notification' do
        expect do
          creator = described_class.new(
            person_id: person.id,
            event_id: event.id
          )
          creator.call
        end.to instrument('attendance.created')
      end
    end
  end
end

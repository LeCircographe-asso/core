# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Attendances', type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe 'GET /admin/attendance_lists/:attendance_list_id/attendances/new' do
    it 'lists only people not already on the list' do
      attendance_list = create(:attendance_list)
      already_added = create(:person)
      create(:attendance, person: already_added, event: nil, attendance_list: attendance_list)
      available = create(:person)

      get new_admin_attendance_list_attendance_path(attendance_list)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(available.full_name)
      expect(response.body).not_to include(already_added.full_name)
    end
  end

  describe 'POST /admin/attendance_lists/:attendance_list_id/attendances' do
    it 'adds the person to the list and redirects to the list page' do
      attendance_list = create(:attendance_list)
      person = create(:person)

      expect do
        post admin_attendance_list_attendances_path(attendance_list), params: {
          attendance: { person_id: person.id, attendance_list_id: attendance_list.id }
        }
      end.to change(Attendance, :count).by(1)

      expect(response).to redirect_to(admin_attendance_list_path(attendance_list))
      expect(Attendance.last.attendance_list_id).to eq(attendance_list.id)
    end
  end

  describe 'DELETE /admin/attendance_lists/:attendance_list_id/attendances/:id' do
    it 'removes the attendance and refunds a consumed pack10 session' do
      attendance_list = create(:attendance_list)
      person = create(:person)
      create(:membership, :circus_full, person: person)
      contribution = create(:contribution, person: person, sessions_remaining: 5)
      attendance = create(:attendance, person: person, event: nil, attendance_list: attendance_list, contribution: contribution)
      expect(contribution.reload.sessions_remaining).to eq(4)

      delete admin_attendance_list_attendance_path(attendance_list, attendance)

      expect(response).to redirect_to(admin_attendance_list_path(attendance_list))
      expect(Attendance.exists?(attendance.id)).to be false
      expect(contribution.reload.sessions_remaining).to eq(5)
    end
  end

  describe 'GET /admin/attendances' do
    it 'renders the paginated list without error' do
      create(:attendance, person: create(:person), event: nil, date: Date.current)

      get admin_attendances_path

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/attendance_lists/:id (participants shown on the list page)' do
    it 'renders the participant table with a working remove button and no dead edit link' do
      attendance_list = create(:attendance_list)
      person = create(:person)
      attendance = create(:attendance, person: person, event: nil, attendance_list: attendance_list)

      get admin_attendance_list_path(attendance_list)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(person.full_name)
      expect(response.body).to include(admin_attendance_list_attendance_path(attendance_list, attendance))
    end
  end
end

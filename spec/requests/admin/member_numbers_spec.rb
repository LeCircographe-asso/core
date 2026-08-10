# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::MemberNumbers', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person) }
  let(:manual_number) { format('%02dC900', Date.current.year % 100) }

  before do
    MemberManagementService.assign_member_number(person, 'BASIQUE')
    login_as(admin)
  end

  describe 'PATCH /admin/member_numbers/:id/change' do
    it 'finds the person from the :id route param and changes the number' do
      patch change_admin_member_number_path(person), params: {
        member_number: manual_number,
        new_membership_type: 'CIRQUE',
        change_notes: 'Migration vers la troupe cirque'
      }

      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body['success']).to be true
      expect(body['new_number']).to eq(manual_number)
      expect(person.reload.member_number).to eq(manual_number)
    end
  end
end

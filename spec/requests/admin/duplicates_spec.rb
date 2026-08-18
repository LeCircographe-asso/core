# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Duplicates', type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe 'GET /admin/duplicates' do
    it 'lists people sharing the same email' do
      # Person#email est unique + normalisé (EmailNormalizable), donc un doublon ne
      # peut pas naître d'une création normale — exactement le scénario qu'un import
      # en masse (Excel/Sheets, hors validations) pourrait produire. On simule ça
      # avec update_column pour forcer l'état, comme le ferait un import bugué.
      person_a = create(:person, email: 'shared@example.com')
      person_b = create(:person, email: 'other@example.com')
      # DB index is case-sensitive; insert_all bypasses normalize_email so a
      # case-variant collides logically (LOWER()) without violating the unique index.
      # rubocop:disable Rails/SkipsModelValidations -- deliberately bypassing normalize_email to simulate a bugged import
      Person.where(id: person_b.id).update_all(email: 'SHARED@example.com')
      # rubocop:enable Rails/SkipsModelValidations

      get admin_duplicates_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(person_a.full_name)
      expect(response.body).to include(person_b.full_name)
    end

    it 'blocks volunteers' do
      login_as(create(:user, :volunteer))

      get admin_duplicates_path

      expect(response).to redirect_to(admin_dashboard_index_path)
    end
  end

  describe 'POST /admin/duplicates/merge' do
    it 'merges the selected records into the target and keeps only the target' do
      keep = create(:person, first_name: 'Keep', email: 'keep@example.com')
      merge_me = create(:person, first_name: 'MergeMe', email: 'mergeme@example.com')
      create(:membership, :circus_full, person: merge_me)

      post merge_admin_duplicates_path, params: {
        target_person_id: keep.id,
        source_person_ids: [ merge_me.id ]
      }

      expect(response).to redirect_to(admin_duplicates_path)
      expect(Person.exists?(merge_me.id)).to be false
      expect(keep.reload.memberships.count).to eq(1)
    end

    it 'redirects with an alert when nothing is selected' do
      post merge_admin_duplicates_path, params: {}

      expect(response).to redirect_to(admin_duplicates_path)
      follow_redirect!
      expect(response.body).to include(I18n.t('admin.duplicates.merge.missing_selection_alert'))
    end
  end
end

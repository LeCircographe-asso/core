# frozen_string_literal: true

require 'rails_helper'
require 'cgi'

RSpec.describe 'Admin::Memberships', type: :request do
  describe 'GET /admin/memberships' do
    context 'when authenticated as admin' do
      let(:admin) { create(:user, :admin) }

      before { login_as(admin) }

      it 'returns http success' do
        get admin_memberships_path
        expect(response).to have_http_status(:success)
      end

      it 'displays list of people with memberships' do
        person1 = create(:person, first_name: 'Alice')
        create(:membership, person: person1, status: :active)
        person2 = create(:person, first_name: 'Bob')
        create(:membership, person: person2, status: :active)

        get admin_memberships_path
        expect(response.body).to include('Alice')
        expect(response.body).to include('Bob')
      end
    end
  end

  describe 'GET /admin/memberships/:id' do
    context 'when authenticated as admin' do
      let(:admin) { create(:user, :admin) }
      let(:person) { create(:person) }
      let(:membership_type) { create(:membership_type) }
      let!(:membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }

      before { login_as(admin) }

      it 'returns http success' do
        get admin_membership_path(person)
        expect(response).to have_http_status(:success)
      end

      it 'displays current membership' do
        get admin_membership_path(person)
        expect(response.body).to include(CGI.escapeHTML(person.full_name))
      end
    end
  end

  describe 'GET /admin/memberships/new' do
    context 'when authenticated as admin' do
      let(:admin) { create(:user, :admin) }
      let(:person) { create(:person) }

      before { login_as(admin) }

      it 'returns http success' do
        get new_admin_membership_path(person_id: person.id)
        expect(response).to have_http_status(:success)
      end

      context 'for upgrade' do
        let(:basic_type) { create(:membership_type, category: :basic) }
        let(:circus_type) { create(:membership_type, category: :circus) }
        let!(:basic_membership) { create(:membership, person: person, membership_type: basic_type, status: :active) }

        it 'shows only circus types for upgrade' do
          get new_admin_membership_path(person_id: person.id, upgrade: 'true')
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Upgrade d&#39;adhésion")
          expect(response.body).to include("plein tarif")
          expect(response.body).not_to include("Tarif réduit éligible")
        end
      end
    end
  end

  describe 'POST /admin/memberships' do
    context 'when authenticated as admin' do
      let(:admin) { create(:user, :admin) }
      let(:person) { create(:person) }
      let(:membership_type) { create(:membership_type) }

      before { login_as(admin) }

      context 'with valid params' do
        it 'creates a membership' do
          expect do
            post admin_memberships_path, params: {
              membership: {
                person_id: person.id,
                membership_type_id: membership_type.id,
                payment_method: 'cash'
              }
            }
          end.to change { Membership.count }.by(1)
        end

        it 'creates a payment' do
          expect do
            post admin_memberships_path, params: {
              membership: {
                person_id: person.id,
                membership_type_id: membership_type.id,
                payment_method: 'cash'
              }
            }
          end.to change { Payment.count }.by(1)
        end

        it 'redirects with success notice' do
          post admin_memberships_path, params: {
            membership: {
              person_id: person.id,
              membership_type_id: membership_type.id,
              payment_method: 'cash'
            }
          }

          expect(response).to redirect_to(admin_user_path("person_#{person.id}"))
        end
      end

      context 'for upgrade' do
        let(:basic_type) { create(:membership_type, :basic, price_cents: 1000) }
        let(:circus_type) { create(:membership_type, :circus, price_cents: 2500) }
        let!(:basic_membership) { create(:membership, person: person, membership_type: basic_type, status: :active) }

        it 'upgrades membership' do
          expect do
            post admin_memberships_path, params: {
              membership: {
                person_id: person.id,
                membership_type_id: circus_type.id,
                payment_method: 'cash',
                upgrade: 'true'
              }
            }
          end.to change { person.reload.current_membership.membership_type_id }.from(basic_type.id).to(circus_type.id)
        end

        it 'creates payment for full price of new type' do
          expect do
            post admin_memberships_path, params: {
              membership: {
                person_id: person.id,
                membership_type_id: circus_type.id,
                payment_method: 'cash',
                upgrade: 'true'
              }
            }
          end.to change { Payment.count }.by(1)
        end

        it 'records a full-price membership payment line for the upgraded membership' do
          post admin_memberships_path, params: {
            membership: {
              person_id: person.id,
              membership_type_id: circus_type.id,
              payment_method: 'cash',
              upgrade: 'true'
            }
          }

          payment = Payment.order(:created_at).last
          line = payment.payment_lines.sole

          expect(payment.total_cents).to eq(circus_type.price_cents)
          expect(line.item_type).to eq('Membership')
          expect(line.amount_cents).to eq(circus_type.price_cents)
          expect(line.item_id).to eq(person.reload.current_membership.id)
          expect(line.description).to include('plein tarif')
        end
      end
    end
  end

  describe 'PATCH /admin/memberships/:id' do
    context 'when authenticated as admin' do
      let(:admin) { create(:user, :admin) }
      let(:person) { create(:person) }
      let(:membership_type) { create(:membership_type) }
      let!(:membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }

      before { login_as(admin) }

      context 'with valid params' do
        it 'updates the membership' do
          new_type = create(:membership_type)

          patch admin_membership_path(person), params: {
            membership: {
              membership_type_id: new_type.id
            }
          }

          membership.reload
          expect(membership.membership_type_id).to eq(new_type.id)
        end

        it 'redirects with success notice' do
          new_type = create(:membership_type)

          patch admin_membership_path(person), params: {
            membership: {
              membership_type_id: new_type.id
            }
          }

          expect(response).to redirect_to(admin_user_path("person_#{person.id}"))
        end
      end
    end
  end

  describe 'DELETE /admin/memberships/:id' do
    context 'when authenticated as admin' do
      let(:admin) { create(:user, :admin) }
      let(:person) { create(:person) }
      let(:membership_type) { create(:membership_type) }
      let!(:membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }

      before { login_as(admin) }

      it 'marks membership as inactive' do
        expect do
          delete admin_membership_path(person)
        end.to change { membership.reload.status }.from('active').to('inactive')
      end

      it 'does not delete the membership' do
        expect do
          delete admin_membership_path(person)
        end.not_to(change { Membership.count })
      end

      it 'redirects with success notice' do
        delete admin_membership_path(person)
        expect(response).to redirect_to(admin_memberships_path)
      end
    end
  end
end

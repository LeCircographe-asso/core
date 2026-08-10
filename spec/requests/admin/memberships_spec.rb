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

      it 'shows the reduced-rate reason field server-side (no JS needed) when the person is already eligible' do
        person.update!(reduced_rate_eligible: true, reduced_rate_reason: 'RSA')
        create(:membership_type, :circus, rate_kind: 'standard')
        create(:membership_type, :circus_reduced, rate_kind: 'reduced')

        get new_admin_membership_path(person_id: person.id)

        doc = Nokogiri::HTML5.fragment(response.body)
        details = doc.at_css('[data-reduced-rate-target="details"]')
        expect(details['class']).not_to include('hidden')
      end

      it 'keeps the reduced-rate reason field hidden server-side when the person is not eligible' do
        create(:membership_type, :circus, rate_kind: 'standard')
        create(:membership_type, :circus_reduced, rate_kind: 'reduced')

        get new_admin_membership_path(person_id: person.id)

        doc = Nokogiri::HTML5.fragment(response.body)
        details = doc.at_css('[data-reduced-rate-target="details"]')
        expect(details['class']).to include('hidden')
      end

      context 'for upgrade' do
        let(:basic_type) { create(:membership_type, category: :basic) }
        let(:circus_type) { create(:membership_type, :circus, name: 'Adhésion Cirque Complète', rate_kind: "standard") }
        let(:circus_reduced_type) { create(:membership_type, :circus_reduced, name: 'Adhésion Cirque Solidaire', rate_kind: "reduced") }
        let(:misleading_standard_type) { create(:membership_type, :circus, name: 'Adhésion Cirque Réduite de Test', rate_kind: "standard") }
        let!(:basic_membership) { create(:membership, person: person, membership_type: basic_type, status: :active) }

        it 'shows only circus types for upgrade' do
          circus_type
          circus_reduced_type

          get new_admin_membership_path(person_id: person.id, upgrade: 'true')
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Passage en adhésion Cirque")
          expect(response.body).to include("Règle d'upgrade")
          expect(response.body).not_to include("Tarif réduit éligible")
          expect(response.body).not_to include("Sélectionnez ci-dessus pour voir le tarif")
        end

        it 'always shows reduced circus memberships, even when the person is not yet reduced-rate eligible' do
          # L'éligibilité au tarif réduit se déclare désormais au moment du choix
          # (voir Admin::MembershipsController#apply_reduced_rate_selection!),
          # plus comme un pré-requis qui filtre les options disponibles.
          circus_type
          circus_reduced_type
          misleading_standard_type

          get new_admin_membership_path(person_id: person.id, upgrade: 'true')

          expect(response.body).to include("Adhésion Cirque Complète")
          expect(response.body).to include("Adhésion Cirque Réduite de Test")
          expect(response.body).to include("Adhésion Cirque Solidaire")
        end

        it 'still shows the eligibility banner when the person is already reduced-rate eligible' do
          person.update!(reduced_rate_eligible: true, reduced_rate_reason: "Étudiant")
          circus_type
          circus_reduced_type

          get new_admin_membership_path(person_id: person.id, upgrade: 'true')

          expect(response.body).to include("Tarif réduit éligible")
          expect(response.body).to include("Étudiant")
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

          expect(response).to redirect_to(admin_member_path(person))
        end

        it 'persists offer_reason for an offered membership' do
          post admin_memberships_path, params: {
            membership: {
              person_id: person.id,
              membership_type_id: membership_type.id,
              payment_method: 'offered',
              offer_reason: 'Solidarity'
            }
          }

          payment = Payment.order(:created_at).last

          expect(payment.payment_method).to eq('offered')
          expect(payment.offer_reason).to eq('Solidarity')
          expect(payment.total_cents).to eq(0)
        end

        it 'adds a donation line when donation amount is provided' do
          post admin_memberships_path, params: {
            membership: {
              person_id: person.id,
              membership_type_id: membership_type.id,
              payment_method: 'cash',
              donation_amount: '5.50'
            }
          }

          payment = Payment.order(:created_at).last

          expect(payment.total_cents).to eq(membership_type.price_cents + 550)
          expect(payment.payment_lines.count).to eq(2)
          expect(payment.payment_lines.find_by(item_type: 'Donation')&.amount_cents).to eq(550)
        end
      end

      context 'when selecting a reduced-rate circus membership type' do
        let(:circus_reduced_type) { create(:membership_type, :circus_reduced, price_cents: 2_000) }

        it 'declares the person reduced-rate eligible with the given reason' do
          expect(person.reduced_rate_eligible?).to be(false)

          post admin_memberships_path, params: {
            membership: { person_id: person.id, membership_type_id: circus_reduced_type.id, payment_method: 'cash' },
            reduced_rate_reason: 'Étudiant'
          }

          person.reload
          expect(person.reduced_rate_eligible?).to be(true)
          expect(person.reduced_rate_reason).to eq('Étudiant')
        end

        it 'creates the membership at the reduced price' do
          post admin_memberships_path, params: {
            membership: { person_id: person.id, membership_type_id: circus_reduced_type.id, payment_method: 'cash' },
            reduced_rate_reason: 'RSA'
          }

          expect(Payment.order(:created_at).last.total_cents).to eq(2_000)
        end

        it 'rejects the request when no reason is given' do
          expect do
            post admin_memberships_path, params: {
              membership: { person_id: person.id, membership_type_id: circus_reduced_type.id, payment_method: 'cash' }
            }
          end.not_to change(Membership, :count)

          expect(person.reload.reduced_rate_eligible?).to be(false)
          expect(response).to redirect_to(new_admin_membership_path(person_id: person.id))
        end

        it 'requires the proof field when the reason is "Autre"' do
          expect do
            post admin_memberships_path, params: {
              membership: { person_id: person.id, membership_type_id: circus_reduced_type.id, payment_method: 'cash' },
              reduced_rate_reason: 'Autre'
            }
          end.not_to change(Membership, :count)

          expect(response).to redirect_to(new_admin_membership_path(person_id: person.id))
        end

        it 'does not touch reduced-rate fields when a standard type is chosen' do
          standard_type = create(:membership_type, :circus)

          post admin_memberships_path, params: {
            membership: { person_id: person.id, membership_type_id: standard_type.id, payment_method: 'cash' }
          }

          expect(person.reload.reduced_rate_eligible?).to be(false)
        end
      end

      context 'with invalid offered params' do
        it 'rejects an offered membership without offer_reason' do
          expect do
            post admin_memberships_path, params: {
              membership: {
                person_id: person.id,
                membership_type_id: membership_type.id,
                payment_method: 'offered',
                offer_reason: ''
              }
            }
          end.not_to change(Payment, :count)

          expect(response).to redirect_to(new_admin_membership_path(person_id: person.id))
          follow_redirect!
          expect(response.body).to include('Une raison doit être fournie')
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
          expect(line.description).to eq("Passage d'adhésion : #{basic_type.name} -> #{circus_type.name}")
        end

        it 'persists offer_reason and donation for an offered upgrade' do
          post admin_memberships_path, params: {
            membership: {
              person_id: person.id,
              membership_type_id: circus_type.id,
              payment_method: 'offered',
              offer_reason: 'Solidarity',
              donation_amount: '4.00',
              upgrade: 'true'
            }
          }

          payment = Payment.order(:created_at).last

          expect(payment.payment_method).to eq('offered')
          expect(payment.offer_reason).to eq('Solidarity')
          expect(payment.total_cents).to eq(400)
          expect(payment.payment_lines.find_by(item_type: 'Membership')&.amount_cents).to eq(0)
          expect(payment.payment_lines.find_by(item_type: 'Donation')&.amount_cents).to eq(400)
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

          expect(response).to redirect_to(admin_member_path(person))
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

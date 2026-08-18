# frozen_string_literal: true

require 'rails_helper'

# Garde-fou contenu UI (audit 2026-05).
#
# Vérifie :
#   - les libellés tarifs publics (cohérence avec docs/glossary.md + seeds)
#   - l'absence des termes legacy/non canoniques retirés de l'audit
#   - la non-prolifération de la carte embarquée (centralisée sur contact_us, Leaflet)
#
# Si un de ces tests casse : soit le contenu a évolué de manière intentionnelle
# (mettre à jour le test + docs), soit une régression de vocabulaire est arrivée.
RSpec.describe 'Public pages content', type: :request do
  describe 'GET /pages/become_member' do
    let!(:circus_membership_type) { create(:membership_type, category: 'circus', rate_kind: 'standard', price_cents: 1000) }

    before do
      create(:membership_type, category: 'circus', rate_kind: 'reduced', price_cents: 700)
      create(:contribution_formula, membership_type: circus_membership_type, duration: 'day', price_cents: 400)
      create(:contribution_formula, membership_type: circus_membership_type, duration: 'pack10', price_cents: 3000, sessions_count: 10, validity_days: 365)
      create(:contribution_formula, membership_type: circus_membership_type, duration: 'trimester', price_cents: 6000)
      create(:contribution_formula, membership_type: circus_membership_type, duration: 'annual', price_cents: 12_000)
    end

    it 'affiche les tarifs canoniques et rejette les termes legacy', :aggregate_failures do
      get adhesion_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Séance libre')
      expect(response.body).to include('Carnet 10 séances')
      expect(response.body).to include('Trimestre (3 mois)')
      expect(response.body).to include('Cotisation annuelle')
      expect(response.body).to include('30 €')
      expect(response.body).to include('60 €')
      expect(response.body).to include('120 €')
      expect(response.body).to include('Tarif réduit — 7 €')
      expect(response.body).to include('10 €')
      expect(response.body).not_to include('Adhésion soutien :')
      expect(response.body).not_to include('20 € / an')
      expect(response.body).not_to include('super soutiens')
      expect(response.body).not_to include('adhésion de soutien')
      expect(response.body).not_to include("souscrivant à l'adhésion soutien")
      expect(response.body).not_to include('data-controller="map"')
    end
  end

  describe 'GET /pages/faq' do
    it 'affiche la FAQ sans termes supprimés ni email direct', :aggregate_failures do
      get faq_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('Pourquoi on prend le temps de répondre')
      expect(response.body).not_to include('Lis-la comme une petite histoire')
      expect(response.body).to include('/contact#contact-form')
      expect(response.body).not_to include('contact@lecircographe.fr')
    end
  end

  describe 'GET /pages/news' do
    it 'affiche les actualités sans doublons de navigation', :aggregate_failures do
      get actualites_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('data-tabs-name-value="horaires"')
      expect(response.body).not_to include("Abonne-toi à la newsletter")
    end

    it "affiche les vraies photos de la galerie dans le carrousel quand elle est peuplée (une seule slide, pas le pool de 12)" do
      image_path = Rails.root.join("app/assets/images/lelieu1.webp")
      GalleryPhoto.create!(image: { io: File.open(image_path), filename: "lelieu1.webp" })

      get actualites_path

      expect(response.body.scan("swiper-slide\"").count).to eq(1)
    end

    it "retombe sur le pool générique (12 slides) quand la galerie est vide" do
      expect(GalleryPhoto.count).to eq(0)

      get actualites_path

      expect(response).to have_http_status(:success)
      expect(response.body.scan("swiper-slide\"").count).to eq(12)
    end
  end

  describe 'GET /pages/contact_us' do
    it 'affiche la carte et le formulaire de contact sans email public', :aggregate_failures do
      get contact_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-controller="map"')
      expect(response.body).to include('data-map-lat-value="43.6195896"')
      expect(response.body).to include('data-map-lng-value="1.4223463"')
      expect(response.body).to include('id="map"')
      expect(response.body).to include('id="contact-form"')
      expect(response.body).not_to include('contact@lecircographe.fr')
      expect(response.body).to include('97 bis Boulevard de Suisse')
      expect(response.body).not_to include('Cartoucherie')
      expect(response.body).not_to include('Maurice Sarraut')
      expect(response.body).not_to include('Tram')
      expect(response.body).to include('id="horaires"')
    end
  end

  describe 'GET /pages/privacy_policy' do
    it "utilise l'email canonique RGPD", :aggregate_failures do
      get confidentialite_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('contact@lecircographe.fr')
      expect(response.body).not_to include('contact@circographe.fr')
    end
  end

  describe 'GET /' do
    it "n'embarque pas de carte (lien vers contact_us#map)", :aggregate_failures do
      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('data-controller="map"')
    end
  end

  describe 'GET /pages/about' do
    it 'affiche les membres du CA et les partenaires depuis la base', :aggregate_failures do
      create(:board_member, name: 'Léa Martin', role: 'Présidente')
      create(:partner, name: 'La Grainerie', category: 'Lieu associé')

      get about_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Léa Martin')
      expect(response.body).to include('La Grainerie')
    end
  end

  describe 'GET /pages/association' do
    it "n'expose pas le CTA hero dupliqué", :aggregate_failures do
      get association_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('Comment adhérer')
    end
  end

  describe 'WCAG accessibility — pages publiques' do
    describe 'GET /' do
      it 'respecte les critères WCAG de base', :aggregate_failures do
        get root_path

        expect(response.body).to include('href="#main-content"')
        expect(response.body).to include('id="main-content"')
        expect(response.body).to include('leading-normal')
        expect(response.body).to include('for="user_email_address"')
        expect(response.body).to include('autocomplete="email"')
        expect(response.body).to include('focus-visible:ring-2')
        expect(response.body).to include('aria-hidden="true"')
        expect(response.body).to include('data-accordion-icon')
      end
    end

    describe 'GET /pages/contact_us' do
      it 'respecte les critères WCAG formulaire et tableau', :aggregate_failures do
        get contact_path

        expect(response.body).to include('<caption')
        expect(response.body).to include('scope="col"')
        expect(response.body).to include('autocomplete="name"')
        expect(response.body).to include('autocomplete="email"')
        expect(response.body).to include('required="required"')
        expect(response.body).to include('ouvre dans un nouvel onglet')
      end
    end
  end
end

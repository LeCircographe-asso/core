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
    before { get adhesion_path }

    it 'renders successfully' do
      expect(response).to have_http_status(:success)
    end

    it 'shows canonical contribution prices (aligned with seeds)' do
      expect(response.body).to include('4 € la journée')
      expect(response.body).to include('Carnet 10 séances :</strong> 30 €')
      expect(response.body).to include('Trimestre (3 mois) :</strong> 60 €')
      expect(response.body).to include('Cotisation annuelle :</strong> 120 €')
    end

    it 'shows canonical membership prices (aligned with seeds)' do
      expect(response.body).to include('Plein tarif : 10 € / an')
      expect(response.body).to include('Tarif réduit : 7 € / an')
    end

    it 'does not promise membership types absent from MembershipType catalog' do
      expect(response.body).not_to include('Adhésion soutien :')
      expect(response.body).not_to include('20 € / an')
    end

    it 'uses canonical contribution duration vocabulary (no legacy "super soutiens")' do
      expect(response.body).not_to include('super soutiens')
    end

    it 'does not duplicate the interactive map (centralized on contact_us#map)' do
      expect(response.body).not_to include('data-controller="map"')
    end
  end

  describe 'GET /pages/faq' do
    before { get faq_path }

    it 'renders successfully' do
      expect(response).to have_http_status(:success)
    end

    it 'no longer renders the meta storytelling sections removed by the audit' do
      expect(response.body).not_to include('Pourquoi on prend le temps de répondre')
      expect(response.body).not_to include('Lis-la comme une petite histoire')
    end

    it 'links FAQ answers about contacting to the contact form, not an inbox address' do
      expect(response.body).to include('/pages/contact_us#contact-form')
      expect(response.body).not_to include('contact@lecircographe.fr')
    end
  end

  describe 'GET /pages/news' do
    before { get actualites_path }

    it 'renders successfully' do
      expect(response).to have_http_status(:success)
    end

    it 'no longer exposes the duplicated "Horaires" tab' do
      expect(response.body).not_to include('data-tabs-name-value="horaires"')
    end

    it 'no longer renders the duplicated newsletter signup (footer is the canonical one)' do
      expect(response.body).not_to include("Abonne-toi à la newsletter")
    end
  end

  describe 'GET /pages/contact_us' do
    before { get contact_path }

    it 'renders successfully' do
      expect(response).to have_http_status(:success)
    end

    it 'is the only public page exposing the interactive map widget' do
      expect(response.body).to include('data-controller="map"')
      expect(response.body).to include('data-map-lat-value="43.6195896"')
      expect(response.body).to include('data-map-lng-value="1.4223463"')
    end

    it 'exposes a stable #map anchor for cross-page links' do
      expect(response.body).to include('id="map"')
    end

    it 'directs contact actions to the on-page form (no public mailbox string)' do
      expect(response.body).to include('id="contact-form"')
      expect(response.body).not_to include('contact@lecircographe.fr')
    end

    it 'shows the unique postal address (boulevard de Suisse, no Cartoucherie)' do
      expect(response.body).to include('97 bis Boulevard de Suisse')
      expect(response.body).not_to include('Cartoucherie')
      expect(response.body).not_to include('Maurice Sarraut')
      expect(response.body).not_to include('Tram')
    end

    it 'exposes #horaires anchor for FAQ deep links' do
      expect(response.body).to include('id="horaires"')
    end
  end

  describe 'GET /pages/privacy_policy' do
    before { get confidentialite_path }

    it 'renders successfully' do
      expect(response).to have_http_status(:success)
    end

    it 'uses the canonical contact email everywhere (RGPD consistency)' do
      expect(response.body).to include('contact@lecircographe.fr')
      expect(response.body).not_to include('contact@circographe.fr')
    end
  end

  describe 'GET /' do
    before { get root_path }

    it 'renders successfully' do
      expect(response).to have_http_status(:success)
    end

    it 'does not embed its own map widget (links to contact_us#map)' do
      expect(response.body).not_to include('data-controller="map"')
    end
  end

  describe 'GET /pages/association' do
    before { get association_path }

    it 'renders successfully' do
      expect(response).to have_http_status(:success)
    end

    it 'no longer exposes the duplicated hero "Comment adhérer" CTA' do
      expect(response.body).not_to include('Comment adhérer')
    end
  end

  describe 'controller-driven FAQ entries' do
    it 'no longer mentions a non-existent "adhésion soutien" payment option' do
      get adhesion_path
      expect(response.body).not_to include('adhésion de soutien')
      expect(response.body).not_to include("souscrivant à l'adhésion soutien")
    end
  end
end

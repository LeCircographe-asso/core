# frozen_string_literal: true

require "rails_helper"

# Legal pages have one template per language: pages/<page>.html.erb (French, default and only
# binding version) and pages/<page>.en.html.erb (indicative English translation).
RSpec.describe "Legal pages by locale", type: :request do
  {
    "terms" => [ "Conditions Générales d'Utilisation", "Terms of Use" ],
    "privacy_policy" => [ "Politique de Confidentialité", "Privacy Policy" ]
  }.each do |page_id, (french_heading, english_heading)|
    describe page_id do
      it "is in French by default" do
        get page_path(page_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(french_heading)
        expect(response.body).not_to include("indicative translation")
      end

      it "is in English, marked as an indicative translation, when the locale is English" do
        I18n.with_locale(:en) { get page_path(page_id) }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(english_heading, "indicative translation")
      end
    end
  end
end

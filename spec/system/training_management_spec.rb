require 'rails_helper'

RSpec.describe "Training Management", type: :system do
  let(:admin) { create(:user, role: 'admin') }
  let(:member) { create(:user, role: 'circus_membership') }
  let(:subscription) { create(:user_membership, user: member) }
  
  before do
    sign_in admin
    visit admin_training_dashboard_path
  end

  describe "Dashboard" do
    it "shows today's session" do
      expect(page).to have_content(Date.current.strftime('%d/%m/%Y'))
    end

    it "shows attendance statistics" do
      expect(page).to have_content("Statistiques")
      expect(page).to have_content("participants")
    end
  end

  describe "Member management" do
    it "can add member with valid subscription" do
      subscription # Create subscription
      
      fill_in "Rechercher", with: member.email
      click_button "Rechercher"
      
      within(".search-results") do
        expect(page).to have_content(member.email)
        click_button "Ajouter"
      end

      expect(page).to have_content("ajouté à la session")
    end

    it "redirects to membership form for invalid subscription" do
      fill_in "Rechercher", with: member.email
      click_button "Rechercher"
      
      within(".search-results") do
        click_button "Adhésion"
      end

      expect(page).to have_current_path(new_admin_member_path)
    end
  end
end 
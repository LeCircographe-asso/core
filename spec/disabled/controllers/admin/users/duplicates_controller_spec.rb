require "rails_helper"

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before do
    # Simuler une session authentifiée
    session = create(:session, user: admin_user)
    cookies.signed[:session_id] = session.id
    allow(controller).to receive(:current_user).and_return(admin_user)
  end

  describe "GET #duplicates" do
    it "returns success" do
      get :duplicates
      expect(response).to have_http_status(:success)
    end

    it "assigns duplicate report" do
      get :duplicates
      expect(assigns(:duplicate_report)).to be_present
    end

    it "renders the duplicates template" do
      get :duplicates
      expect(response).to render_template(:duplicates)
    end

    it "sets breadcrumbs" do
      get :duplicates
      breadcrumb_titles = assigns(:breadcrumbs).map(&:first)
      expect(breadcrumb_titles).to include("Détection des doublons")
    end
  end

  # Note: Les tests POST #merge ne sont pas applicables car la route merge n'existe pas encore
  # Ces tests seront ajoutés quand la fonctionnalité sera implémentée

  describe "authorization" do
    context "when user is not admin" do
      before do
        # Simuler une session avec un utilisateur non-admin
        session = create(:session, user: regular_user)
        cookies.signed[:session_id] = session.id
        allow(controller).to receive(:current_user).and_return(regular_user)
      end

      it "redirects non-admin users" do
        get :duplicates
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Vous n'avez pas accès à cette page")
      end
    end

    context "when user is not signed in" do
      before do
        # Supprimer la session
        cookies.delete(:session_id)
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it "redirects to login" do
        get :duplicates
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end

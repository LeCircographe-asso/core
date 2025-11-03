require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  describe "GET /admin/users" do
    context "when not authenticated" do
      it "redirects to login" do
        get admin_users_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated as web_visitor" do
      let(:user) { create(:user, system_role: :web_visitor) }
      
      before { login_as(user) }
      
      it "redirects to root with alert" do
        get admin_users_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("accès")
      end
    end

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }
      
      before { login_as(admin) }
      
      it "returns http success" do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it "displays list of people" do
        person1 = create(:person, first_name: "Alice", last_name: "Smith")
        person2 = create(:person, first_name: "Bob", last_name: "Jones")
        
        get admin_users_path
        expect(response.body).to include("Alice")
        expect(response.body).to include("Bob")
      end

      it "filters by active status" do
        active_person = create(:person, deleted_at: nil)
        deleted_person = create(:person, deleted_at: Time.current)
        
        get admin_users_path
        expect(response.body).to include(active_person.first_name)
        expect(response.body).not_to include(deleted_person.first_name)
      end
    end
  end

  describe "GET /admin/users/:id" do
    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }
      let(:person) { create(:person, first_name: "John", last_name: "Doe") }
      
      before { login_as(admin) }
      
      it "shows person with user" do
        user = create(:user, person: person)
        
        get admin_user_path(user)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("John")
        expect(response.body).to include("Doe")
      end
      
      it "shows person without user (person_123 format)" do
        get admin_user_path("person_#{person.id}")
        expect(response).to have_http_status(:success)
        expect(response.body).to include("John")
      end
      
      it "returns 404 for non-existent person" do
        get admin_user_path("person_99999")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /admin/users/:id/restore" do
    context "when authenticated as super_admin" do
      let(:super_admin) { create(:user, :super_admin) }
      let(:deleted_user) { create(:user, deleted_at: 1.day.ago, deleted: true) }
      
      before { login_as(super_admin) }
      
      it "restores the user" do
        expect {
          post restore_admin_user_path(deleted_user)
        }.to change { deleted_user.reload.deleted_at }.from(Time).to(nil)
        
        deleted_user.reload
        expect(deleted_user.deleted_at).to be_nil
      end
      
      it "redirects to users list with notice" do
        post restore_admin_user_path(deleted_user)
        expect(response).to redirect_to(admin_users_path)
        follow_redirect!
        expect(response.body).to include("restauré")
      end
    end
    
    context "when authenticated as admin (not super)" do
      let(:admin) { create(:user, :admin) }
      let(:deleted_user) { create(:user, deleted_at: 1.day.ago, deleted: true) }
      
      before { login_as(admin) }
      
      it "does not allow restoration" do
        expect {
          post restore_admin_user_path(deleted_user)
        }.not_to change { deleted_user.reload.deleted_at }
        
        expect(response).to redirect_to(admin_users_path)
        follow_redirect!
        expect(response.body).to include("super-admin")
      end
    end
  end

  describe "DELETE /admin/users/:id" do
    context "when authenticated as super_admin" do
      let(:super_admin) { create(:user, :super_admin) }
      let(:regular_user) { create(:user) }
      
      before { login_as(super_admin) }
      
      it "deletes the user from database" do
        delete admin_user_path(regular_user)
        follow_redirect! if response.redirect?
        
        expect { regular_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
      
      it "does not allow deleting self" do
        expect {
          delete admin_user_path(super_admin)
        }.not_to change { User.count }
        
        expect(response).to redirect_to(admin_users_path)
      end
    end
  end
end


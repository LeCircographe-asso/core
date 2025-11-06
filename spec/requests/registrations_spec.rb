require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  describe "GET /registration/new" do
    context "when not authenticated" do
      it "returns http success" do
        get new_registration_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }
      
      before { login_as(user) }
      
      it "redirects to root" do
        get new_registration_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /registration" do
    context "with valid params" do
      let(:valid_params) do
        {
          user: {
            email_address: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "John",
            last_name: "Doe",
            cgu: "1",
            privacy_policy: "1",
            newsletter_subscribed: "1"
          }
        }
      end

      it "creates a user" do
        expect {
          post registration_path, params: valid_params
        }.to change { User.count }.by(1)
      end
      
      it "creates a person" do
        expect {
          post registration_path, params: valid_params
        }.to change { Person.count }.by(1)
      end
      
      it "creates a newsletter subscriber if requested" do
        expect {
          post registration_path, params: valid_params
        }.to change { NewsletterSubscriber.count }.by(1)
      end
      
      it "creates a session" do
        expect {
          post registration_path, params: valid_params
        }.to change { Session.count }.by(1)
      end
      
      it "redirects to root with success notice" do
        post registration_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
      
      it "sends welcome email" do
        expect {
          post registration_path, params: valid_params
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end
    
    context "without newsletter subscription" do
      let(:valid_params) do
        {
          user: {
            email_address: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "John",
            last_name: "Doe",
            cgu: "1",
            privacy_policy: "1",
            newsletter_subscribed: "0"
          }
        }
      end

      it "does not create newsletter subscriber" do
        expect {
          post registration_path, params: valid_params
        }.not_to change { NewsletterSubscriber.count }
      end
      
      it "still creates user and person" do
        expect {
          post registration_path, params: valid_params
        }.to change { User.count }.by(1)
          .and change { Person.count }.by(1)
      end
    end
    
    context "with existing email" do
      let!(:existing_user) { create(:user, email_address: "existing@example.com") }
      
      it "does not create duplicate user" do
        expect {
          post registration_path, params: {
            user: {
              email_address: "existing@example.com",
              password: "password123",
              password_confirmation: "password123",
              first_name: "John",
              last_name: "Doe",
              cgu: "1",
              privacy_policy: "1"
            }
          }
        }.not_to change { User.count }
      end
      
      it "renders new with error" do
        post registration_path, params: {
          user: {
            email_address: "existing@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "John",
            last_name: "Doe",
            cgu: "1",
            privacy_policy: "1"
          }
        }
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("S'inscrire")
      end
    end
    
    context "without CGU" do
      it "does not create user" do
        expect {
          post registration_path, params: {
            user: {
              email_address: "newuser@example.com",
              password: "password123",
              password_confirmation: "password123",
              first_name: "John",
              last_name: "Doe",
              privacy_policy: "1"
            }
          }
        }.not_to change { User.count }
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("CGU")
      end
    end
    
    context "without privacy policy" do
      it "does not create user" do
        expect {
          post registration_path, params: {
            user: {
              email_address: "newuser@example.com",
              password: "password123",
              password_confirmation: "password123",
              first_name: "John",
              last_name: "Doe",
              cgu: "1"
            }
          }
        }.not_to change { User.count }
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("confidentialité")
      end
    end
    
    context "with password mismatch" do
      it "does not create user" do
        expect {
          post registration_path, params: {
            user: {
              email_address: "newuser@example.com",
              password: "password123",
              password_confirmation: "different",
              first_name: "John",
              last_name: "Doe",
              cgu: "1",
              privacy_policy: "1"
            }
          }
        }.not_to change { User.count }
        
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end


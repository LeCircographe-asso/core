# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  describe 'GET /sessions/new' do
    context 'when not authenticated' do
      it 'returns http success' do
        get new_session_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when authenticated' do
      let(:user) { create(:user) }

      before { login_as(user) }

      it 'redirects to root' do
        get new_session_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST /sessions' do
    let(:user) { create(:user, password: 'password123') }

    context 'with valid credentials' do
      it 'creates a session' do
        expect do
          post session_path, params: {
            email_address: user.email_address,
            password: 'password123'
          }
        end.to change { Session.count }.by(1)
      end

      it 'sets the session cookie' do
        post session_path, params: {
          email_address: user.email_address,
          password: 'password123'
        }

        cookie_header = response.headers['Set-Cookie']
        expect(cookie_header).to be_present
        expect(cookie_header.is_a?(Array) ? cookie_header.first : cookie_header).to include('session_id')
      end

      it 'redirects to root with success notice' do
        post session_path, params: {
          email_address: user.email_address,
          password: 'password123'
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('réussie')
      end

      it 'redirects to return_to url if present' do
        get admin_users_path # Simulate protected page
        follow_redirect! # Get redirected to login

        post session_path, params: {
          email_address: user.email_address,
          password: 'password123'
        }

        expect(response).to redirect_to(admin_users_path)
      end
    end

    context 'with invalid credentials' do
      it 'does not create a session' do
        expect do
          post session_path, params: {
            email_address: user.email_address,
            password: 'wrongpassword'
          }
        end.not_to(change { Session.count })
      end

      it 'redirects with error message' do
        post session_path, params: {
          email_address: user.email_address,
          password: 'wrongpassword'
        }

        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include('invalide')
      end
    end

    context 'with non-existent email' do
      it 'does not create a session' do
        expect do
          post session_path, params: {
            email_address: 'nonexistent@example.com',
            password: 'password123'
          }
        end.not_to(change { Session.count })
      end

      it 'redirects with error message' do
        post session_path, params: {
          email_address: 'nonexistent@example.com',
          password: 'password123'
        }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'rate limiting' do
      it 'allows 10 requests within 3 minutes' do
        10.times do
          post session_path, params: {
            email_address: 'test@example.com',
            password: 'wrongpassword'
          }
        end

        expect(response).to redirect_to(new_session_path)
      end

      it 'blocks after 10 requests' do
        11.times do |_i|
          post session_path, params: {
            email_address: 'test@example.com',
            password: 'wrongpassword'
          }
        end

        expect(response).to redirect_to(new_session_url)
        follow_redirect!
        expect(response.body).to include('Rééssayez plus tard')
      end
    end
  end

  describe 'DELETE /sessions' do
    context 'when authenticated' do
      let(:user) { create(:user) }
      let(:session) { user.sessions.create!(user_agent: 'Test', ip_address: '127.0.0.1') }

      before do
        login_as(user)
        @current_session = session
        Current.session = session
      end

      it 'destroys the session' do
        expect do
          delete session_path
        end.to change { Session.where(id: session.id).count }.by(-1)
      end

      it 'redirects to root with success notice' do
        delete session_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('Déconnecté')
      end
    end

    context 'when not authenticated' do
      it "still redirects (doesn't crash)" do
        delete session_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end

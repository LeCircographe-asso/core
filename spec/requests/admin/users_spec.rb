require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  describe "POST /admin/users" do
    let(:admin) { create(:user, :admin) }

    before do
      login_as(admin)
      @previous_route_host = Rails.application.routes.default_url_options[:host]
      @previous_mailer_host = ActionMailer::Base.default_url_options[:host]
      Rails.application.routes.default_url_options[:host] = "www.example.com"
      ActionMailer::Base.default_url_options[:host] = "www.example.com"
    end

    after do
      Rails.application.routes.default_url_options[:host] = @previous_route_host
      ActionMailer::Base.default_url_options[:host] = @previous_mailer_host
    end

    context "when creating a brand new person" do
      let(:membership_type) { create(:membership_type, :circus, price_cents: 2500) }

      it "creates person, membership, payment and optional web account" do
        expect {
          post admin_users_path, params: {
            user: {
              create_membership: "1",
              membership_type_id: membership_type.id,
              payment_method: "cash",
              create_web_account: "1",
              system_role: "volunteer",
              email_address: "jane.doe@local.test",
              person: {
                first_name: "Jane",
                last_name: "Doe",
                email: "jane.doe@local.test",
                phone: "0600000000",
                newsletter_subscribed: "1"
              }
            }
          }
        }.to change(Person, :count).by(1)
         .and change(Membership, :count).by(1)
         .and change(Payment, :count).by(1)
         .and change(NewsletterSubscriber, :count).by(1)

        person = Person.order(:created_at).last
        expect(response).to redirect_to(admin_user_path("person_#{person.id}"))

        membership = person.memberships.last
        payment = person.payments.last

        expect(membership).not_to be_nil
        expect(payment.total_cents).to eq(2500)
        expect(payment.payment_lines.first.item_id).to eq(membership.id)
        expect(payment.recorded_by).to eq(admin)
        expect(person.user).to be_present
      end
    end

    context "when binding a web account to an existing person" do
      let(:person) { create(:person, email: "existing@example.com") }

      it "creates a user account and redirects to the person profile" do
        expect {
          post admin_users_path, params: {
            user: {
              person_id: person.id,
              create_web_account: "1",
              system_role: "volunteer",
              email_address: "existing@example.com"
            }
          }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(admin_user_path("person_#{person.id}"))
        expect(person.reload.user).to be_present
      end
    end

    context "with invalid attributes" do
      it "re-renders the form with errors" do
        expect {
          post admin_users_path, params: {
            user: {
              create_membership: "1",
              membership_type_id: nil,
              person: {
                first_name: "",
                last_name: "",
                email: ""
              }
            }
          }
        }.not_to change(Person, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to include("Invalid data")
      end
    end
  end

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

  describe "PATCH /admin/users/:id" do
    let(:admin) { create(:user, :admin) }

    before { login_as(admin) }

    context "when targeting a person entity" do
      let(:target_person) { create(:person, first_name: "Lucie", last_name: "Martin", phone: "0102030405") }

      it "updates person attributes via PersonUpdater" do
        patch admin_user_path("person_#{target_person.id}"), params: {
          person: {
            first_name: "Lucile",
            phone: "0606060606",
            newsletter_subscribed: "1"
          }
        }

        expect(response).to redirect_to(admin_user_path("person_#{target_person.id}"))
        expect(target_person.reload.first_name).to eq("Lucile")
        expect(target_person.phone).to eq("0606060606")
      end

      it "returns validation errors when data invalid" do
        patch admin_user_path("person_#{target_person.id}"), params: {
          person: {
            first_name: "",
            last_name: "",
            newsletter_subscribed: "0"
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Validation errors")
        expect(target_person.reload.first_name).to eq("Lucie")
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

  describe "DELETE /admin/users/:id (person identifier)" do
    let(:admin) { create(:user, :admin) }

    before { login_as(admin) }

    it "archives the person via UserDeleter" do
      person = create(:person)

      expect {
        delete admin_user_path("person_#{person.id}")
      }.to change { person.reload.deleted_at.present? }.from(false).to(true)

      expect(response).to redirect_to(admin_users_path)
    end

    it "prevents deletion if financial data exists" do
      person = create(:person)
      create(:membership, person: person)

      expect {
        delete admin_user_path("person_#{person.id}")
      }.not_to change { person.reload.deleted_at }

      follow_redirect!
      expect(response.body).to include("Cannot delete person")
    end
  end
end

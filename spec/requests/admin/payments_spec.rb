require 'rails_helper'

RSpec.describe "Admin::Payments", type: :request do
  describe "GET /admin/payments" do
    context "when not authenticated" do
      it "redirects to login" do
        get admin_payments_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated as web_visitor" do
      let(:user) { create(:user, system_role: :web_visitor) }
      
      before { login_as(user) }
      
      it "redirects to root with alert" do
        get admin_payments_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("accès")
      end
    end

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }
      let(:person) { create(:person) }
      
      before { login_as(admin) }
      
      it "returns http success" do
        get admin_payments_path
        expect(response).to have_http_status(:success)
      end

      it "displays list of payments" do
        payment = create(:payment, person: person, recorded_by: admin, total_cents: 5000, payment_method: "cash")
        
        get admin_payments_path
        expect(response.body).to include(person.full_name)
        expect(response.body).to include("50.00")
      end

      it "filters by user_id" do
        person1 = create(:person, first_name: "Alice")
        person2 = create(:person, first_name: "Bob")
        payment1 = create(:payment, person: person1, recorded_by: admin, total_cents: 5000)
        payment2 = create(:payment, person: person2, recorded_by: admin, total_cents: 3000)
        
        get admin_payments_path, params: { user_id: person1.id }
        expect(response.body).to include("Alice")
        expect(response.body).not_to include("Bob")
      end
    end
  end

  describe "GET /admin/payments/new" do
    let(:admin) { create(:user, :admin) }
    
    before { login_as(admin) }
    
    it "returns http success" do
      get new_admin_payment_path
      expect(response).to have_http_status(:success)
    end
    
    context "with user_id param" do
      let(:person) { create(:person) }
      let(:user) { create(:user, person: person) }
      
      it "returns http success with user context" do
        get new_admin_payment_path, params: { user_id: user.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /admin/payments" do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }
    
    before { login_as(admin) }
    
    context "with valid attributes" do
      it "creates a payment" do
        expect {
          post admin_payments_path, params: {
            payment: {
              person_id: person.id,
              total_cents: 5000,
              payment_method: "cash",
              notes: "Test payment"
            }
          }
        }.to change { Payment.count }.by(1)
      end
      
      it "sets recorded_by to current user" do
        post admin_payments_path, params: {
          payment: {
            person_id: person.id,
            total_cents: 5000,
            payment_method: "cash"
          }
        }
        
        payment = Payment.last
        expect(payment.recorded_by).to eq(admin)
      end
      
      it "converts euros to cents" do
        post admin_payments_path, params: {
          payment: {
            person_id: person.id,
            total_cents: 50.50, # euros
            payment_method: "cash"
          }
        }
        
        payment = Payment.last
        expect(payment.total_cents).to eq(5050) # centimes
      end
      
      it "redirects to payments index with success notice" do
        post admin_payments_path, params: {
          payment: {
            person_id: person.id,
            total_cents: 5000,
            payment_method: "cash"
          }
        }
        
        expect(response).to redirect_to(admin_payments_path)
        follow_redirect!
        expect(response.body).to include("succès")
      end
    end
    
    context "with invalid attributes" do
      it "does not create a payment without person_id" do
        expect {
          post admin_payments_path, params: {
            payment: {
              total_cents: 5000,
              payment_method: "cash"
            }
          }
        }.not_to change { Payment.count }
      end
      
      it "redirects with error message" do
        post admin_payments_path, params: {
          payment: {
            total_cents: 5000,
            payment_method: "cash"
          }
        }
        
        expect(response).to redirect_to(admin_payments_path)
        follow_redirect!
        expect(response.body).to include("Erreur")
      end
    end
  end

  describe "PATCH /admin/payments/:id" do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }
    let(:payment) { create(:payment, person: person, recorded_by: admin, total_cents: 5000, payment_method: "cash") }
    
    before { login_as(admin) }
    
    context "with valid attributes" do
      it "updates the payment" do
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: 75.00, # euros, controller converts to 7500 centimes
            payment_method: "card",
            status: "success"
          }
        }
        
        payment.reload
        expect(payment.total_cents).to eq(7500) # in cents
        expect(payment.payment_method).to eq("card")
      end
      
      it "converts euros to cents" do
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: 100.75,
            payment_method: "cash",
            status: "success"
          }
        }
        
        payment.reload
        expect(payment.total_cents).to eq(10075)
      end
      
      it "redirects with success notice" do
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: 75.00, # euros
            payment_method: "cash",
            status: "success"
          }
        }
        
        expect(response).to redirect_to(admin_payments_path)
      end
    end
    
    context "with invalid attributes" do
      it "does not update the payment" do
        original_cents = payment.total_cents
        
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: -100
          }
        }
        
        payment.reload
        expect(payment.total_cents).to eq(original_cents)
      end
      
      it "redirects with error message" do
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: -100
          }
        }
        
        expect(response).to redirect_to(admin_payments_path)
        follow_redirect!
        expect(response.body).to include("Échec")
      end
    end
  end

  describe "DELETE /admin/payments/:id" do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }
    let!(:payment) { create(:payment, person: person, recorded_by: admin, total_cents: 5000, status: :success) }
    
    before { login_as(admin) }
    
    it "marks payment as cancelled" do
      expect {
        delete admin_payment_path(payment)
      }.to change { payment.reload.status }.from("success").to("cancel")
      
      expect(payment.cancelled?).to be_truthy
    end
    
    it "creates audit log entry" do
      expect {
        delete admin_payment_path(payment)
      }.to change { PaymentAuditLog.count }.by(1)
      
      audit_log = PaymentAuditLog.last
      expect(audit_log.payment_id).to eq(payment.id)
      expect(audit_log.user_id).to eq(admin.id)
    end
    
    it "redirects with success notice" do
      delete admin_payment_path(payment)
      expect(response).to redirect_to(admin_payments_path)
      follow_redirect!
      expect(response.body).to include("annulé")
    end
  end

  describe "GET /admin/payments/:id/show" do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }
    let(:payment) { create(:payment, person: person, recorded_by: admin) }
    
    before { login_as(admin) }
    
    it "redirects to payments index with notice" do
      get admin_payment_path(payment)
      expect(response).to redirect_to(admin_payments_path)
    end
  end
end


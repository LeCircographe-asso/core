require "rails_helper"

RSpec.describe Admin::UserCreationForm do
  let(:admin_user) { create(:user, :admin) }
  let(:session) { admin_user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1") }

  before do
    Current.session = session
  end

  after do
    Current.session = nil
    session.destroy
  end

  describe "#call" do
    context "when creating a brand new person with membership and web account" do
      let(:membership_type) { create(:membership_type, :circus, price_cents: 2500) }

      it "creates the person, membership, payment, newsletter and user" do
        form = described_class.new(
          first_name: "Jane",
          last_name: "Doe",
          email: "jane.doe@example.com",
          phone: "0600000000",
          newsletter_subscribed: true,
          create_membership: true,
          membership_type_id: membership_type.id,
          payment_method: "cash",
          create_web_account: true,
          email_address: "jane.doe@example.com",
          system_role: "volunteer"
        )

        result = nil
        expect {
          result = form.call
        }.to change(Person, :count).by(1)
         .and change(Membership, :count).by(1)
         .and change(Payment, :count).by(1)
         .and change(NewsletterSubscriber, :count).by(1)
         .and change(User, :count).by(1)

        expect(result.success?).to be(true)
        expect(result.message).to include("succès")

        person = Person.order(:created_at).last
        membership = person.memberships.last
        payment = person.payments.last

        expect(person.user).to be_present
        expect(person.user.system_role).to eq("volunteer")
        expect(membership.membership_type).to eq(membership_type)
        expect(payment.total_cents).to eq(2500)
        expect(payment.recorded_by).to eq(admin_user)
        expect(payment.payment_lines.first.item_id).to eq(membership.id)
        subscriber = NewsletterSubscriber.find_by(person: person)
        expect(subscriber).not_to be_nil
        expect(subscriber.subscribed?).to be(true)
      end
    end

    context "when creating a web account for an existing person" do
      let(:person) { create(:person, email: "existing@example.com") }

      it "attaches a user to the person" do
        form = described_class.new(
          person_id: person.id,
          create_web_account: true,
          email_address: "existing@example.com",
          system_role: "volunteer"
        )

        result = nil
        expect {
          result = form.call
        }.to change(User, :count).by(1)

        expect(result.success?).to be(true)
        expect(person.reload.user).to be_present
        expect(person.user.system_role).to eq("volunteer")
      end
    end

    context "when attributes are invalid" do
      it "returns a failure with error messages" do
        form = described_class.new(create_membership: true, membership_type_id: nil, payment_method: "cash")

        result = form.call

        expect(result.success?).to be(false)
        expect(result.errors.join(", ")).to include("Invalid data")
      end
    end

    context "when person already has a user" do
      let(:person) { create(:person, email: "duplicate@example.com") }

      before do
        create(:user, person: person)
      end

      it "fails to create another web account" do
        form = described_class.new(
          person_id: person.id,
          create_web_account: true,
          email_address: "duplicate@example.com",
          system_role: "volunteer"
        )

        result = nil
        expect {
          result = form.call
        }.not_to change(User, :count)

        expect(result.success?).to be(false)
        expect(result.errors.join(", ")).to include("déjà un compte web")
      end
    end
  end
end

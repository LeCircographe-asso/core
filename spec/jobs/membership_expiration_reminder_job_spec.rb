# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipExpirationReminderJob, type: :job do
  include ActiveJob::TestHelper

  let(:person) { create(:person) }
  let!(:user)  { create(:user, person: person) }

  describe "#perform" do
    context "avec une adhésion active expirant dans 30 jours" do
      let!(:membership) { create(:membership, person: person, ended_at: 30.days.from_now.to_date, status: :active) }

      it "envoie un email de rappel" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(UserMailer, :membership_expiration_reminder).with(membership)
      end
    end

    context "avec une adhésion expirant dans 29 jours" do
      let!(:membership) { create(:membership, person: person, ended_at: 29.days.from_now.to_date, status: :active) }

      it "n'envoie pas d'email" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(UserMailer, :membership_expiration_reminder)
      end
    end

    context "avec une adhésion inactive expirant dans 30 jours" do
      let!(:membership) { create(:membership, person: person, ended_at: 30.days.from_now.to_date, status: :expired) }

      it "n'envoie pas d'email" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(UserMailer, :membership_expiration_reminder)
      end
    end

    context "avec plusieurs adhésions actives expirant dans 30 jours" do
      let(:person2) { create(:person) }
      let!(:user2)  { create(:user, person: person2) }
      let!(:membership1) { create(:membership, person: person,  ended_at: 30.days.from_now.to_date, status: :active) }
      let!(:membership2) { create(:membership, person: person2, ended_at: 30.days.from_now.to_date, status: :active) }

      it "envoie un email par adhésion" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(UserMailer, :membership_expiration_reminder).exactly(2).times
      end
    end

    context "sans adhésion concernée" do
      it "n'envoie aucun email" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(UserMailer, :membership_expiration_reminder)
      end
    end
  end
end

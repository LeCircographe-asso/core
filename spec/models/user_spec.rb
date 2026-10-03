# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'basic functionality' do
    it 'can be created' do
      user = User.new(email: 'test@example.com')
      expect(user).to be_present
    end
  end

  describe 'date scopes (using created_at via Dateable)' do
    include ActiveSupport::Testing::TimeHelpers

    around do |example|
      travel_to(Time.zone.local(2026, 4, 29, 12, 0, 0)) { example.run }
    end

    let!(:today_user) { create(:user, created_at: Date.current.beginning_of_day + 12.hours) }
    let!(:this_week_user) { create(:user, created_at: Date.current.beginning_of_week.beginning_of_day + 12.hours) }
    let!(:last_week_user) do
      create(:user, created_at: (Date.current.beginning_of_week - 1.day).beginning_of_day + 12.hours)
    end

    describe '.today' do
      it 'returns only users created today' do
        expect(User.today).to include(today_user)
        expect(User.today).not_to include(this_week_user, last_week_user)
      end
    end

    describe '.this_week' do
      it 'returns users created this week' do
        this_week = User.this_week
        expect(this_week).to include(today_user, this_week_user)
        expect(this_week).not_to include(last_week_user)
      end
    end

    describe '.this_month' do
      it 'returns users created this month' do
        this_month = User.this_month
        expect(this_month).to include(today_user, this_week_user)
        # last_week_user should be included if it's in the same month
        if last_week_user.created_at.to_date.month == Date.current.month
          expect(this_month).to include(last_week_user)
        else
          expect(this_month).not_to include(last_week_user)
        end
      end
    end
  end

  describe 'Dateable instance methods' do
    let(:user) { create(:user, created_at: Date.current.beginning_of_day + 14.hours) }

    describe '#today?' do
      it 'returns true for user created today' do
        expect(user.today?(:created_at)).to be true
      end

      it 'returns false for user created yesterday' do
        old_user = create(:user, created_at: Date.yesterday.beginning_of_day + 14.hours)
        expect(old_user.today?(:created_at)).to be false
      end
    end

    describe '#this_week?' do
      it 'returns true for user created this week' do
        expect(user.this_week?(:created_at)).to be true
      end
    end

    describe '#this_month?' do
      it 'returns true for user created this month' do
        expect(user.this_month?(:created_at)).to be true
      end
    end

    describe '#formatted_date' do
      it 'formats created_at date' do
        formatted = user.formatted_date(:created_at)
        expect(formatted).to match(%r{\d{2}/\d{2}/\d{4}})
      end
    end
  end

  describe 'DDD vocabulary naming' do
    let(:person) { create(:person) }
    let(:user) { create(:user, person: person) }

    describe '#subordinate_roles' do
      it 'returns subordinate roles for an admin' do
        user.update!(system_role: :admin)
        expect(user.subordinate_roles).to match_array(%w[volunteer web_visitor])
      end
    end

    describe '#can_change_role_of?' do
      let(:super_admin) { create(:user, :super_admin) }
      let(:admin) { create(:user, :admin) }
      let(:volunteer) { create(:user, :volunteer) }
      let(:web_visitor) { create(:user) }

      it 'lets a super_admin change the role of admins, volunteers and web visitors' do
        expect([ admin, volunteer, web_visitor ].map { |u| super_admin.can_change_role_of?(u) }).to all(be(true))
      end

      it 'never lets anyone change the role of a super_admin, including another super_admin' do
        other_super_admin = create(:user, :super_admin)

        expect(super_admin.can_change_role_of?(other_super_admin)).to be(false)
        expect(admin.can_change_role_of?(super_admin)).to be(false)
      end

      it 'lets an admin change only strictly lower roles' do
        expect(admin.can_change_role_of?(volunteer)).to be(true)
        expect(admin.can_change_role_of?(web_visitor)).to be(true)
        expect(admin.can_change_role_of?(create(:user, :admin))).to be(false)
      end

      it 'never allows changing your own role' do
        expect(super_admin.can_change_role_of?(super_admin)).to be(false)
        expect(admin.can_change_role_of?(admin)).to be(false)
      end

      it 'gives volunteers and web visitors no role management at all' do
        expect(volunteer.can_change_role_of?(web_visitor)).to be(false)
        expect(web_visitor.can_change_role_of?(create(:user))).to be(false)
      end
    end

    describe '#active_membership?' do
      it 'returns false when person has no active membership' do
        expect(user.active_membership?).to be false
      end
    end
  end

  describe "email format" do
    it "rejects an email_address without a valid format" do
      user = build(:user, email_address: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to be_present
    end
  end

  describe "email identity consistency" do
    it "blocks a user email already used by another person record" do
      create(:person, email: "another.person@example.com")
      user = build(:user, email_address: "another.person@example.com")

      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("entre en conflit avec l'email d'une autre personne")
    end

    it "allows a user email when it matches their own person email" do
      person = create(:person, email: "linked.identity@example.com")
      user = build(:user, person: person, email_address: "linked.identity@example.com")

      expect(user).to be_valid
    end
  end

  # Régression : lancé hors requête (rake circographe:create_super_admin, console), l'URL de
  # réinitialisation levait « Missing host to link to » et annulait toute la création du compte.
  describe "#welcome_send for an admin-created account" do
    it "builds the password URL with the mailer host, without any request" do
      user = create(:user, system_role: "admin", created_by_admin: true)
      mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      allow(UserMailer).to receive(:welcome_by_admin).and_return(mail)

      expect { user.welcome_send }.not_to raise_error
      expect(UserMailer).to have_received(:welcome_by_admin)
        .with(user, %r{\Ahttps?://example\.com/passwords/.+/edit})
    end
  end
end

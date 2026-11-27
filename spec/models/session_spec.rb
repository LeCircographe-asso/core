# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'creation' do
    it 'can be created with factory' do
      session = create(:session, user: user)
      expect(session).to be_persisted
      expect(session.user).to eq(user)
    end
  end

  def session_for(role, idle_for:)
    user = create(:user, system_role: role)
    user.sessions.create!(user_agent: "rspec", ip_address: "127.0.0.1").tap do |session|
      session.update_column(:updated_at, idle_for.ago)
    end
  end

  describe "#idle_expired?" do
    it "expires staff sessions past their role timeout" do
      expect(session_for(:admin, idle_for: 16.minutes)).to be_idle_expired
      expect(session_for(:super_admin, idle_for: 16.minutes)).to be_idle_expired
      expect(session_for(:volunteer, idle_for: 31.minutes)).to be_idle_expired
    end

    it "keeps staff sessions within their role timeout" do
      expect(session_for(:admin, idle_for: 14.minutes)).not_to be_idle_expired
      expect(session_for(:volunteer, idle_for: 29.minutes)).not_to be_idle_expired
    end

    it "never expires web visitor sessions" do
      expect(session_for(:web_visitor, idle_for: 30.days)).not_to be_idle_expired
    end
  end

  describe "#track_activity!" do
    it "touches a session idle for more than the throttle" do
      session = session_for(:admin, idle_for: 2.minutes)

      expect { session.track_activity! }.to change { session.reload.updated_at }
    end

    it "skips the write within the throttle window" do
      session = session_for(:admin, idle_for: 30.seconds)

      expect { session.track_activity! }.not_to change { session.reload.updated_at }
    end
  end
end

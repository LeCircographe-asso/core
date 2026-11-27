# frozen_string_literal: true

require "rails_helper"

# List pages preload memberships/contributions; the in-memory path must give
# exactly what the SQL scopes give.
RSpec.describe Person, "status with preloaded associations" do
  let(:person) { create(:person) }

  def preloaded
    described_class.includes(:memberships, :contributions).find(person.id)
  end

  it "finds the same current membership as the scope" do
    create(:membership, :expired, person:, started_at: 2.years.ago, ended_at: 1.year.ago)
    current = create(:membership, person:)

    expect(preloaded.current_membership).to eq(current)
    expect(person.reload.current_membership).to eq(current)
  end

  it "returns nil when only a future or inactive membership exists" do
    create(:membership, :inactive, person:)
    create(:membership, person:, started_at: 1.month.from_now, ended_at: 13.months.from_now)

    expect(preloaded.current_membership).to be_nil
    expect(person.reload.current_membership).to be_nil
  end

  it "selects the same currently active contributions as the scope" do
    kept = [
      create(:contribution, person:),
      create(:contribution, person:, expires_at: nil),
      create(:contribution, person:, expires_at: Date.current.beginning_of_day)
    ]
    create(:contribution, :expired, person:)
    create(:contribution, person:, status: :suspended)
    create(:contribution, person:).tap { |c| c.update!(expires_at: 1.day.ago.end_of_day) }

    expect(preloaded.currently_active_contributions).to match_array(kept)
    expect(person.reload.currently_active_contributions).to match_array(kept)
  end

  it "does not query when associations are preloaded" do
    create(:membership, person:)
    create(:contribution, person:)
    record = preloaded

    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      record.current_membership
      record.currently_active_contributions
    end

    expect(queries).to eq(0)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe StagingMailGuard do
  def build_message(to:, cc: nil, bcc: nil, subject: "Bienvenue")
    Mail.new do
      from "staging@example.org"
      self.to = to
      self.cc = cc if cc
      self.bcc = bcc if bcc
      self.subject = subject
      body "Hello"
    end
  end

  def apply(message, allowlist: "", redirect_to: "")
    described_class.apply(message, env: { "MAIL_ALLOWLIST" => allowlist, "MAIL_REDIRECT_TO" => redirect_to })
  end

  context "with nothing configured" do
    it "sends nothing" do
      message = build_message(to: "member@example.com")

      expect(apply(message)).to eq(:suppressed)
      expect(message.perform_deliveries).to be(false)
    end
  end

  context "with an allowlist" do
    it "delivers to listed addresses and domains, case-insensitively" do
      message = build_message(to: [ "Alice@Team.org", "bob@asso.fr" ])

      expect(apply(message, allowlist: "alice@team.org, @asso.fr")).to eq(:delivered)
      expect(message.to).to eq([ "Alice@Team.org", "bob@asso.fr" ])
      expect(message.perform_deliveries).to be(true)
    end

    it "drops the other recipients, including cc and bcc" do
      message = build_message(to: [ "alice@team.org", "member@example.com" ], cc: "other@example.com", bcc: "spy@example.com")

      expect(apply(message, allowlist: "alice@team.org")).to eq(:delivered)
      expect(message.to).to eq([ "alice@team.org" ])
      expect(message.cc).to be_nil
      expect(message.bcc).to be_nil
    end

    it "does not take a lookalike domain for an allowed one" do
      message = build_message(to: "eve@evilasso.fr")

      expect(apply(message, allowlist: "@asso.fr")).to eq(:suppressed)
    end
  end

  context "with a redirect inbox" do
    it "sends what is blocked to the test inbox, showing the original recipients" do
      message = build_message(to: "member@example.com", cc: "alice@team.org", subject: "Rappel")

      expect(apply(message, allowlist: "alice@team.org", redirect_to: "tests@team.org")).to eq(:redirected)
      expect(message.to).to eq([ "tests@team.org" ])
      expect(message.cc).to eq([ "alice@team.org" ])
      expect(message.subject).to eq("[staging → member@example.com] Rappel")
      expect(message.header["X-Staging-Original-Recipients"].value).to eq("member@example.com")
      expect(message.perform_deliveries).to be(true)
    end
  end

  it "logs the outcome with masked addresses" do
    allow(Rails.logger).to receive(:info)

    apply(build_message(to: "member@example.com"))

    expect(Rails.logger).to have_received(:info).with(a_string_including("[StagingMailGuard] suppressed", "blocked=m***@example.com"))
  end

  describe "registration" do
    it "is wired in the staging environment only" do
      staging = Rails.root.join("config/environments/staging.rb").read
      production = Rails.root.join("config/environments/production.rb").read

      expect(staging).to include("config.action_mailer.interceptors = %w[StagingMailGuard]")
      expect(production).not_to include("StagingMailGuard")
    end
  end

  describe "end to end through a real mailer" do
    it "redirects a membership reminder addressed to a member" do
      membership = create(:membership)
      mail = UserMailer.membership_expiration_reminder(membership).message

      expect(apply(mail, redirect_to: "tests@team.org")).to eq(:redirected)
      expect(mail.to).to eq([ "tests@team.org" ])
      expect(mail.subject).to start_with("[staging → #{membership.person.email}]")
    end
  end
end

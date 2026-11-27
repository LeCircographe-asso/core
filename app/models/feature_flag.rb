# frozen_string_literal: true

# Read-only registry of the app's feature flags, for the super admin status
# screen. Flags keep their own source of truth (ENV read at boot, database
# setting, environment); this only reports the live value and how to change it.
class FeatureFlag
  Entry = Data.define(:key, :enabled, :source, :setting)

  def self.all
    [
      Entry.new(:public_registration, Rails.application.config.x.public_registration_enabled, :env, "PUBLIC_REGISTRATION_ENABLED"),
      Entry.new(:account_claim, Rails.application.config.x.account_claim_enabled, :env, "ACCOUNT_CLAIM_ENABLED"),
      Entry.new(:mailer_deliveries, ActionMailer::Base.perform_deliveries, :env, "MAILER_DELIVERIES_ENABLED"),
      Entry.new(:bug_report_widget, BugReportWidgetSetting.current.enabled?, :database, "BugReportWidgetSetting"),
      Entry.new(:umami_session_replay, Rails.env.staging?, :environment, "staging")
    ]
  end
end

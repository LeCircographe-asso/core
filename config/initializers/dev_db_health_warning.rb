# frozen_string_literal: true

return unless Rails.env.development?

Rails.application.config.after_initialize do
  next unless defined?(Rails::Server)
  next unless defined?(::User) && defined?(::Session)

  begin
    users_count = User.count
    sessions_count = Session.count

    if users_count.zero?
      DevIncidentLogger.log!(
        type: "empty_development_db_detected",
        details: { users_count: users_count, sessions_count: sessions_count }
      )
      Rails.logger.warn(
        "[dev.db.guard] Empty development DB detected (users_count=0 sessions_count=#{sessions_count}). " \
        "If unexpected, run: bin/rails circographe:fix_local_db — or full data: bin/rails db:seed"
      )
    end

    missing_system_accounts = %w[super-admin@rails.com admin@rails.com volunteer@rails.com].reject do |email|
      User.exists?(email_address: email)
    end

    if missing_system_accounts.any?
      DevIncidentLogger.log!(
        type: "missing_system_accounts_detected",
        details: {
          users_count: users_count,
          missing_system_accounts: missing_system_accounts
        }
      )
      Rails.logger.warn(
        "[dev.db.guard] Missing system account(s): #{missing_system_accounts.join(', ')}. " \
        "Run: bin/rails circographe:seed_system_accounts (or bin/rails circographe:fix_local_db)"
      )
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
    Rails.logger.warn("[dev.db.guard] DB health check skipped: #{e.class} #{e.message}")
  end
end

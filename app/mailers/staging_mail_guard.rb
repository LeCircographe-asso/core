# frozen_string_literal: true

# Mail interceptor for staging only (config/environments/staging.rb): staging holds test
# data and, later, real members being imported, so no mail may reach someone outside the
# team, while every flow stays testable end to end.
#
#   MAIL_ALLOWLIST    comma-separated addresses or @domains delivered as is (the team)
#   MAIL_REDIRECT_TO  one inbox receiving every other mail, subject prefixed with
#                     "[staging → original recipients]"
#
# Recipients outside the allowlist are removed (To, Cc, Bcc). With MAIL_REDIRECT_TO the mail
# goes there instead; without it, a mail left with no recipient is not sent at all. Nothing
# configured = nothing sent. Each mail logs one line: delivered, redirected or suppressed.
class StagingMailGuard
  FIELDS = %i[to cc bcc].freeze

  def self.delivering_email(message)
    apply(message, env: ENV)
  end

  # Returns :delivered, :redirected or :suppressed (also logged).
  def self.apply(message, env:)
    allowlist = parse_list(env.fetch("MAIL_ALLOWLIST", ""))
    redirect_to = env.fetch("MAIL_REDIRECT_TO", "").strip.presence

    blocked = []
    FIELDS.each do |field|
      addresses = Array(message.public_send(field))
      next if addresses.empty?

      kept, removed = addresses.partition { |address| allowed?(address, allowlist) }
      blocked.concat(removed)
      message.public_send("#{field}=", kept.presence)
    end

    outcome =
      if blocked.empty?
        :delivered
      elsif redirect_to
        redirect(message, redirect_to, blocked)
        :redirected
      elsif FIELDS.all? { |field| Array(message.public_send(field)).empty? }
        message.perform_deliveries = false
        :suppressed
      else
        :delivered
      end

    log(outcome, message, blocked)
    outcome
  end

  def self.parse_list(value)
    value.split(",").map { |entry| entry.strip.downcase }.reject(&:empty?)
  end

  def self.allowed?(address, allowlist)
    address = address.to_s.downcase
    allowlist.any? { |entry| entry.start_with?("@") ? address.end_with?(entry) : address == entry }
  end

  def self.redirect(message, redirect_to, blocked)
    message.header["X-Staging-Original-Recipients"] = blocked.join(", ")
    message.to = (Array(message.to) + [ redirect_to ]).uniq
    message.subject = "[staging → #{blocked.join(', ')}] #{message.subject}"
  end

  # j***@example.org: enough to follow a flow in the logs without storing full addresses.
  def self.mask(address)
    local, domain = address.to_s.split("@", 2)
    domain ? "#{local.to_s[0]}***@#{domain}" : "***"
  end

  def self.log(outcome, message, blocked)
    recipients = FIELDS.flat_map { |field| Array(message.public_send(field)) }
    Rails.logger.info(
      "[StagingMailGuard] #{outcome} subject=#{message.subject.to_s.truncate(80).inspect} " \
      "to=#{recipients.map { |a| mask(a) }.join(',')} blocked=#{blocked.map { |a| mask(a) }.join(',')}"
    )
  end

  private_class_method :parse_list, :allowed?, :redirect, :log
end

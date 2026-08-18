# Mailjet Setup

> **Status:** Standby (awaiting Circographe account access)
> **Principle:** Personal account (dev/staging) → Circographe account (prod)

## Strategy

**Never test with prod Circographe account.** Use personal account for dev/staging, so emails go to `dev@` / `staging@christophe.perso` (zero risk to members).

## Configuration

### Dev/Staging (personal account)

```ruby
# config/environments/development.rb
config.action_mailer.smtp_settings = {
  address: "in-v3.mailjet.com",
  port: 587,
  user_name: Rails.application.credentials.mailjet.sandbox.api_key,
  password: Rails.application.credentials.mailjet.sandbox.secret_key,
  authentication: :plain,
  enable_starttls_auto: true
}
config.action_mailer.default_from = "dev@christophe.perso"
```

Store credentials in `config/credentials.yml.enc` (local, never commit).

### Production (Circographe account)

```ruby
# config/environments/production.rb
config.action_mailer.smtp_settings = {
  user_name: ENV["MAILJET_API_KEY"] || Rails.application.credentials.circographe.api_key,
  password: ENV["MAILJET_SECRET"] || Rails.application.credentials.circographe.secret_key,
  ...
}
config.action_mailer.default_from = "noreply@lecircographe.fr"
```

Secrets via `.kamal/secrets` (Kamal deploy).

## Mailers to Configure

1. UserMailer.welcome_email
2. PasswordsMailer.reset, .changed
3. AccountClaimMailer.confirmation_email

## Pre-Production Checklist

- [ ] Templates tested (dev)
- [ ] No HTML injection
- [ ] RGPD unsubscribe links work
- [ ] Rate limiting respected
- [ ] Bounce handling implemented

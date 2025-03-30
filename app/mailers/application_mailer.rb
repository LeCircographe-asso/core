class ApplicationMailer < ActionMailer::Base
  default from: "circographe.mail@gmail.com"
  layout "mailer"

  after_action do
    mail.deliver_later if Rails.env.production? 
  end
end
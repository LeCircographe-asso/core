Mailjet.configure do |config|
  config.api_key = ENV['MAILJET_API_PUBLIC']
  config.secret_key = ENV['MAILJET_API_SECRET']
  config.default_from = 'circographe.mail@gmail.com'
end

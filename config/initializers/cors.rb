# frozen_string_literal: true

unless Rails.env.production?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins "*"
      resource "/assets/*",
               headers: :any,
               methods: %i[get options]
    end
  end
end

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "flowbite", to: "flowbite.turbo.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "password_visibility", to: "password_visibility.js"
pin "@rails/ujs", to: "rails-ujs.js"
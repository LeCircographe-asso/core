# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "home_animations", to: "home_animations.js"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "global_animations", to: "global_animations.js"
pin "swiper" # @12.0.3
pin "swiper/bundle", to: "swiper--bundle.js" # @12.0.3

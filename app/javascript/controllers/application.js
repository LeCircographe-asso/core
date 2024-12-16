import { Application } from "@hotwired/stimulus"
import { Application } from "@hotwired/turbo-rails"

import "./controllers/cookie_popup_controller";

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }


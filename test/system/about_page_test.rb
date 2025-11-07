require "application_system_test_case"

class AboutPageTest < ApplicationSystemTestCase
  test "shows partners on about page" do
    visit page_path("about")

    assert_selector "h1", text: "À propos du Circographe"
    assert_selector "[data-controller='timeline'] .timeline-step", minimum: 3, visible: :all, wait: 5
  end
end

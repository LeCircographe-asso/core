require "application_system_test_case"

class HomePageTest < ApplicationSystemTestCase
  test "home page shows upcoming events frame" do
    visit root_path

    assert_selector "h1", text: /Circographe/i
    assert_selector "turbo-frame#events_upcoming"
    assert_selector "section", text: /Horaires d'ouverture/
  end
end

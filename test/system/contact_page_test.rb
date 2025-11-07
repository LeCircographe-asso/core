require "application_system_test_case"

class ContactPageTest < ApplicationSystemTestCase
  test "contact page renders form turbo frame and FAQ" do
    visit page_path("contact_us")

    assert_selector "h1", text: /Contact/
    assert_selector "turbo-frame#contact_form", wait: 5
    assert_selector "[data-controller='accordion']", visible: :all, wait: 5
  end
end

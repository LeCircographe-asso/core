require "application_system_test_case"

class FaqPageTest < ApplicationSystemTestCase
  test "faq page shows sections and anchors" do
    visit page_path("faq")

    assert_selector "h1", text: /Questions fréquentes/
    assert_selector "a[href='#faq-adhesion']"
    assert_selector "a", text: "Adhésion", wait: 5
    assert_selector "a", text: "Contact"
    assert_selector "a", text: "Vie du lieu"
  end
end

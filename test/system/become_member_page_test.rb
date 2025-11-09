require "application_system_test_case"

class BecomeMemberPageTest < ApplicationSystemTestCase
  test "adhesion page shows timeline and checklist" do
    visit page_path("become_member")

    assert_selector "h1", text: /Adhérer/
    assert_selector "[data-controller='timeline'] .timeline-step", minimum: 3, wait: 5
    assert_selector "[data-controller='checklist'] li", minimum: 1, visible: :all
  end
end

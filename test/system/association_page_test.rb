require "application_system_test_case"

class AssociationPageTest < ApplicationSystemTestCase
  test "association page exposes anchor sections" do
    visit page_path("association")

    assert_selector "h1", text: /Bienvenue au Circographe/
    assert_selector "section#le-cirque", wait: 5, visible: :all
    assert_selector "section#les-arts-graphiques", visible: :all
    assert_selector "section#fonctionnement", visible: :all
  end
end

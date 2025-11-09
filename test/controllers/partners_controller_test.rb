require "test_helper"

class PartnersControllerTest < ActionDispatch::IntegrationTest
  test "returns partners partial as turbo stream" do
    get partners_url(format: :turbo_stream)

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "Ville de Toulouse"
  end

  test "redirects to about page for html requests" do
    get partners_url

    assert_redirected_to page_path("about")
  end
end

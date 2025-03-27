require "test_helper"

class Admin::ProductOrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get admin_product_orders_create_url
    assert_response :success
  end
end

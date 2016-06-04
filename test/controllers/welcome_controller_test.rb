require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get welcome" do
    get welcome_welcome_url
    assert_response :success
  end

  test "should get matchmaking" do
    get welcome_matchmaking_url
    assert_response :success
  end

  test "should get spectating" do
    get welcome_spectating_url
    assert_response :success
  end

  test "should get administration" do
    get welcome_administration_url
    assert_response :success
  end

end

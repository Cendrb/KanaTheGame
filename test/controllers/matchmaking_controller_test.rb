require 'test_helper'

class MatchmakingControllerTest < ActionDispatch::IntegrationTest
  test "should get welcome" do
    get matchmaking_welcome_url
    assert_response :success
  end

  test "should get ranked" do
    get matchmaking_ranked_url
    assert_response :success
  end

  test "should get friendly" do
    get matchmaking_friendly_url
    assert_response :success
  end

  test "should get spectate" do
    get matchmaking_spectate_url
    assert_response :success
  end

end

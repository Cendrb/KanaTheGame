require 'test_helper'

class ShapesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shape = shapes(:one)
  end

  test "should get index" do
    get shapes_url
    assert_response :success
  end

  test "should get new" do
    get new_shape_url
    assert_response :success
  end

  test "should create shape" do
    assert_difference('Shape.count') do
      post shapes_url, params: { shape: { board_data: @shape.board_data, name: @shape.name, points: @shape.points } }
    end

    assert_redirected_to shape_path(Shape.last)
  end

  test "should show shape" do
    get shape_url(@shape)
    assert_response :success
  end

  test "should get edit" do
    get edit_shape_url(@shape)
    assert_response :success
  end

  test "should update shape" do
    patch shape_url(@shape), params: { shape: { board_data: @shape.board_data, name: @shape.name, points: @shape.points } }
    assert_redirected_to shape_path(@shape)
  end

  test "should destroy shape" do
    assert_difference('Shape.count', -1) do
      delete shape_url(@shape)
    end

    assert_redirected_to shapes_path
  end
end

App.shapes.render_shape = (target_div, shape_json) ->
  renderer = new App.shapes.ShapeRenderer(target_div)
  renderer.render(shape_json)
  target_div.css('height', renderer.get_total_height(shape_json) * App.shapes.ShapeRenderer.one_stone_width)

$( document ).ready ->
  $('.shape_board_render').each ->
    shape_div = $(this)
    shape_div.text("downloading shapes...")
    App.shapes.get (shapes) =>
      shape_div.empty()
      App.shapes.render_shape(shape_div, JSON.parse(App.shapes.find_by_id(shape_div.data("id")).board_data))

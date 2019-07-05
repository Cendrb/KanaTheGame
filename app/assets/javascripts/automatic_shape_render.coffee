App.shapes.render_shape = (target_div, shape_json) ->
  renderer = new App.shapes.ShapeRenderer(target_div)
  renderer.render(shape_json)
  target_div.css('height', renderer.get_total_height(shape_json) * App.shapes.ShapeRenderer.one_stone_width)

append_rendered_shape = ($parent_div, shape_data) ->
  render_div = $("<div/>", {class: "shape_variant"})
  App.shapes.render_shape(render_div, shape_data)
  $parent_div.append(render_div)

$( document ).ready ->
  $('.shape_board_render').each ->
    $shape_div = $(this)
    $shape_div.text("downloading shapes...")
    App.shapes.Shapes.run_when_ready (shapes) =>
      $shape_div.empty()
      data = App.shapes.Shapes.find_by_id($shape_div.data("id"))
      append_rendered_shape($shape_div, JSON.parse(variant)) for variant in data.variants

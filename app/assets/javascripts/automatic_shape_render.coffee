$( document ).ready ->
  $('.shape_board_render').each ->
    shape = $(this);
    renderer = new App.shapes.ShapeRenderer(shape);
    renderer.render(shape.data('json'))
    shape.css('height', renderer.get_total_height(shape.data('json')) * App.shapes.ShapeRenderer.one_stone_width)
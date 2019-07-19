App.shapes.ShapeRenderer = class ShapeRenderer
  constructor: (board_div) ->
    @one_field_width = 50
    @main_svg = board_div

  render: (board_obj) ->
    stones_obj = board_obj['stones']
    for stone in stones_obj
      this.render_stone(stone['x'], stone['y'], stone['stone_owner_flag'])

  render_stone: (x, y, stone_owner_flag) ->
    stone = this.create_stone(x, y)
    stone.className = 'stone shape_stone'
    stone.style.top = y * 50 + 'px'
    stone.style.left = x * 50 + 'px'
    stone.innerHTML = stone_owner_flag
    @main_svg.append(stone)

  get_total_height: (board_obj) ->
    stones_obj = board_obj['stones']
    total_height = 0
    for stone in stones_obj
      if Number(stone['y']) > total_height
        total_height = Number(stone['y'])
    return total_height + 1

App.shapes.MatchRenderer = class MatchRenderer extends ShapeRenderer
  constructor: (main_svg) ->
    @one_field_width = 50
    @stone_radius = 20
    @stone_offset = [2, 2]
    @field_scale = 0.86
    @current_render_revision = 0
    @grid_rendered = false
    @main_svg = main_svg
    @main_svg.setAttribute 'class', 'rendered_board'

    @defs_element = document.createElementNS('http://www.w3.org/2000/svg', 'defs')
    @main_svg.appendChild(@defs_element)

  render: (board_obj, fulfilled_shapes_obj) ->
    boardWidth = board_obj['width'] * @one_field_width
    boardHeight = board_obj['height'] * @one_field_width
    @main_svg.setAttribute 'viewBox', "0 0 #{boardWidth} #{boardHeight}"

    @current_render_revision += 1

    unless @grid_rendered
      this.render_grid board_obj['width'], board_obj['height']
      @grid_rendered = true

    stones_obj = board_obj['stones']
    App.Players.run_when_ready (players) =>
      this.render_player_gradients(players)

      for stone in stones_obj
        previous_stone = @main_svg.querySelector(
          "[data-current_render_revision=\"#{@current_render_revision - 1}\"][data-id=\"#{stone['id']}\"]"
        )
        if previous_stone
          this.animate_stone_to previous_stone, stone['x'], stone['y'], stone['player_id']
        else
          this.render_stone stone['id'], stone['x'], stone['y'], stone['player_id']

      #for fulfilled_shape in fulfilled_shapes_obj
      #  if !fulfilled_shape.traded
      #    this.render_fulfilled_shape(fulfilled_shape.id, fulfilled_shape.name, fulfilled_shape.points, fulfilled_shape.player_id, JSON.parse(fulfilled_shape.board_data).stones)

      previous_render_elements = @main_svg.querySelectorAll(
        "[data-current_render_revision=\"#{@current_render_revision - 1}\"]"
      )
      previous_render_elements.forEach((el) -> el.style.opacity = 0)
      setTimeout(() ->
          previous_render_elements.forEach((el) -> el.parentNode.removeChild(el))
        , 1000)

  render_grid: (width, height) ->
    for x in [0..width]
      for y in [0..height]
        field = document.createElementNS 'http://www.w3.org/2000/svg', 'path'
        field.setAttribute 'd', 'm6.296296,0l38.407408,0c0.881481,3.022222 3.274074,5.288889 6.296296,6.17037l0,38.407408c-3.022222,0.881481 -5.414815,3.274074 -6.296296,6.296296l-38.407408,0c-0.881481,-3.022222 -3.274074,-5.414815 -6.296296,-6.296296l0,-38.407408c3.022222,-0.881481 5.414815,-3.148148 6.296296,-6.17037z'
        field.setAttribute 'transform', "translate(#{x * @one_field_width}, #{y * @one_field_width}) scale(#{@field_scale} #{@field_scale})"
        field.setAttribute 'class', 'field'

        @main_svg.appendChild field

    for x in [0..width + 1]
      for y in [0..height + 1]
        circle = document.createElementNS 'http://www.w3.org/2000/svg', 'circle'
        circle.setAttribute 'cx', x * @one_field_width - 3
        circle.setAttribute 'cy', y * @one_field_width - 3
        circle.setAttribute 'r', 5
        circle.setAttribute 'class', 'circle'

        @main_svg.appendChild circle


  animate_stone_to: (stone, new_x, new_y, new_player_id) ->
    stone.setAttribute 'cx', new_x * @one_field_width + @stone_radius + @stone_offset[0]
    stone.setAttribute 'cy', new_y * @one_field_width + @stone_radius + @stone_offset[1]

    # sets player_id and stone coords to data-properties
    stone.dataset.x = new_x
    stone.dataset.y = new_y
    stone.dataset.player_id = new_player_id
    stone.dataset.current_render_revision = this.current_render_revision

    # render colors and player names
    player = App.Players.find_by_id(new_player_id)
    stone.innerHTML = player.name
    stone.style.backgroundColor = player.color

  render_player_gradients: (players) ->
    for player in players
      gradient = document.createElementNS('http://www.w3.org/2000/svg', 'radialGradient')
      gradient.setAttribute 'id', "player_#{player.id}"
      gradient.setAttribute 'cx', '66%'
      gradient.setAttribute 'cy', '66%'
      gradient.setAttribute 'fx', '66%'
      gradient.setAttribute 'fy', '66%'

      gradient.dataset.current_render_revision = @current_render_revision

      stop1 = document.createElementNS('http://www.w3.org/2000/svg', 'stop')
      stop1.setAttribute 'offset', '0'
      stop1.style.stopColor = 'rgb(149, 152, 156)'
      gradient.appendChild stop1

      stop2 = document.createElementNS('http://www.w3.org/2000/svg', 'stop')
      stop2.setAttribute 'offset', '0.270588'
      stop2.style.stopColor = 'rgb(84, 86, 89)'
      gradient.appendChild stop2

      stop3 = document.createElementNS('http://www.w3.org/2000/svg', 'stop')
      stop3.setAttribute 'offset', '1'
      stop3.style.stopColor = player.color #'rgb(19, 21, 22)'
      gradient.appendChild stop3

      @defs_element.appendChild gradient


  render_stone: (id, x, y, player_id) ->
    stone = document.createElementNS 'http://www.w3.org/2000/svg', 'circle'
    stone.setAttribute 'class', 'stone'
    stone.setAttribute 'cx', x * @one_field_width + @stone_radius + @stone_offset[0]
    stone.setAttribute 'cy', y * @one_field_width + @stone_radius + @stone_offset[1]
    stone.setAttribute 'r', @stone_radius
    stone.setAttribute 'fill', "url('#player_#{player_id}')"

    # sets id, player_id and stone coords to data-properties
    stone.dataset.id = id
    stone.dataset.x = x
    stone.dataset.y = y
    stone.dataset.player_id = player_id
    stone.dataset.current_render_revision = @current_render_revision

    @main_svg.append(stone)

  render_fulfilled_shape: (id, name, points, player_id, stones) ->
    # add polygon data
    polygon = document.createElementNS('http://www.w3.org/2000/svg', 'polygon')
    
    polygon.style.stroke = "red"
    polygon.setAttribute('class', 'fulfilled_shape')
    for stone in stones
      this.append_point(
        stone.x * 50,
        stone.y * 50,
        polygon)
      this.append_point(
        (stone.x + 1) * 50,
        stone.y * 50,
        polygon)
      this.append_point(
        (stone.x + 1) * 50,
        (stone.y + 1) * 50,
        polygon)
      this.append_point(
        stone.x * 50,
        (stone.y + 1) * 50,
        polygon)

    # render colors
    player = App.Players.find_by_id(player_id)
    polygon.style.fill = player.color

    # set data
    polygon.dataset.current_render_revision = this.current_render_revision
    polygon.dataset.id = id
    polygon.dataset.player_id = player_id
    polygon.dataset.points = points
    polygon.dataset.name = name

    this.svg_element.appendChild(polygon)

  append_point: (x, y, parent) ->
    point = this.svg_element.createSVGPoint()
    point.x = x
    point.y = y
    parent.points.appendItem(point)

App.shapes.ShapeRenderer = class ShapeRenderer
  @one_stone_width: 55

  constructor: (board_div) ->
    @main_element = board_div

  render: (board_obj) ->
    stones_obj = board_obj['stones']
    for stone in stones_obj
      this.render_stone(stone['x'], stone['y'], stone['stone_owner_flag'])

  render_stone: (x, y, stone_owner_flag) ->
    stone = document.createElement('div')
    stone.className = 'stone shape_stone'
    stone.style.top = y * 50 + 'px'
    stone.style.left = x * 50 + 'px'
    stone.innerHTML = stone_owner_flag
    @main_element.append(stone)

  get_total_height: (board_obj) ->
    stones_obj = board_obj['stones']
    total_height = 0
    for stone in stones_obj
      if Number(stone['y']) > total_height
        total_height = Number(stone['y'])
    return total_height + 1

App.shapes.MatchRenderer = class MatchRenderer
  @one_stone_width: 55
  current_render_revision: 0

  constructor: (board_div) ->
    this.main_element = board_div

  render: (board_obj) ->
    this.main_element.css('width', board_obj['width'] * App.shapes.MatchRenderer.one_stone_width)
    this.main_element.css('height', board_obj['height'] * App.shapes.MatchRenderer.one_stone_width)
    this.current_render_revision += 1
    stones_obj = board_obj['stones']
    App.players.get (players) =>
      for stone in stones_obj
        previous_stone = this.main_element.find("[data-current_render_revision=#{this.current_render_revision - 1}][data-id=#{stone['id']}]")
        if previous_stone.length > 0
          this.animate_stone_to(previous_stone[0], stone['x'], stone['y'], stone['player_id'])
        else
          this.render_stone(stone['id'], stone['x'], stone['y'], stone['player_id'])
      stones_to_be_removed = this.main_element.find("[data-current_render_revision=#{this.current_render_revision - 1}]")
      stones_to_be_removed.css('opacity', 0)
      setTimeout(() =>
          stones_to_be_removed.remove()
        ,1000)

  animate_stone_to: (stone, new_x, new_y, new_player_id) ->
    stone.style.top = new_y * 50 + 'px'
    stone.style.left = new_x * 50 + 'px'

    # sets player_id and stone coords to data-properties
    stone.dataset.x = new_x
    stone.dataset.y = new_y
    stone.dataset.player_id = new_player_id
    stone.dataset.current_render_revision = this.current_render_revision

    # render colors and player names
    player = App.players.find_by_id(new_player_id)
    stone.innerHTML = player.name
    stone.style.backgroundColor = player.color

  render_stone: (id, x, y, player_id) ->
    stone = document.createElement('div')
    stone.className = 'stone match_stone'
    stone.style.top = y * 50 + 'px'
    stone.style.left = x * 50 + 'px'

    # sets id, player_id and stone coords to data-properties
    stone.dataset.id = id
    stone.dataset.x = x
    stone.dataset.y = y
    stone.dataset.player_id = player_id
    stone.dataset.current_render_revision = this.current_render_revision

    # render colors and player names
    player = App.players.find_by_id(player_id)
    stone.innerHTML = player.name
    stone.style.backgroundColor = player.color
    this.main_element.append(stone)

App.shapes.ShapeRenderer = class ShapeRenderer
  @one_stone_width: 48

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
  @one_stone_width: 48

  constructor: (board_div) ->
    @main_element = board_div

  render: (board_obj) ->
    console.log(board_obj)
    @main_element.css('width', board_obj['width'] * App.shapes.MatchRenderer.one_stone_width)
    @main_element.css('height', board_obj['height'] * App.shapes.MatchRenderer.one_stone_width)
    stones_obj = board_obj['stones']
    if window.players
      for stone in stones_obj
        this.render_stone(stone['x'], stone['y'], stone['player_id'])
    else
      this.fetch_players(board_obj)

  render_stone: (x, y, player_id) ->
    stone = document.createElement('div')
    stone.className = 'stone match_stone'
    stone.style.top = y * 50 + 'px'
    stone.style.left = x * 50 + 'px'
    player = (window.players.filter (obj) ->
      return obj.id == player_id)[0]
    stone.innerHTML = player.name
    stone.style.backgroundColor = player.color
    @main_element.append(stone)

  fetch_players: (board_obj) ->
    $.getJSON "/players.json", (data) =>
      window.players = data
      this.render(board_obj)

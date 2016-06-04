class ShapeRenderer
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

class MatchRenderer
  constructor: (board_div) ->
    @main_element = board_div

  render: (board_obj) ->
    stones_obj = board_obj['stones']
    if window.players
      for stone in stones_obj
        this.render_stone(stone['x'], stone['y'], stone['player_id'])
    else
      this.fetch_players(json_string)

  render_stone: (x, y, player_id) ->
    stone = document.createElement('div')
    stone.className = 'stone match_stone'
    stone.style.top = y * 50 + 'px'
    stone.style.left = x * 50 + 'px'
    console.log(window.players)
    player = (window.players.filter (obj) ->
      console.log(obj.id)
      console.log(player_id)
      return obj.id == player_id)[0]
    stone.innerHTML = player.name
    stone.style.backgroundColor = player.color
    @main_element.append(stone)

  fetch_players: (json_string) ->
    $.getJSON "/players.json", (data) =>
      window.players = data
      this.parse_and_render(json_string)

$( document ).ready ->
  $('.shape_board_render').each ->
    shape = $(this);
    renderer = new ShapeRenderer(shape);
    renderer.render(shape.data('json'))
    shape.css('height', renderer.get_total_height(shape.data('json')) * 50)

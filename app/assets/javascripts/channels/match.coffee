$ ->
  $("h1").on 'click', (event) ->
    App.match.refresh()

  $("#repopulate_board").on 'click', (event) ->
    App.match.repopulate()

  selected_stone = null
  stone_being_clicked = false

  $("#main_board").on 'click', (event) ->
    if !stone_being_clicked && selected_stone
      console.log("======CLICKED ON BOARD======")
      # board absolute location
      boardAbsoluteX = $(this).offset().left
      boardAbsoluteY = $(this).offset().top

      # click relative position
      clickRelativeToBoardX = event.pageX - boardAbsoluteX
      clickRelativeToBoardY = event.pageY - boardAbsoluteY

      # click stone coords
      xStoneCoord = Math.floor(clickRelativeToBoardX / 50)
      yStoneCoord = Math.floor(clickRelativeToBoardY / 50)

      App.match.play(selected_stone.x, selected_stone.y, xStoneCoord, yStoneCoord)
      deselect_stone()
    stone_being_clicked = false

  App.match.setup_stone_handlers = ->
    $(".match_stone").on 'click', (event) ->
      if !selected_stone
        console.log("======CLICKED ON STONE======")
        stone_being_clicked = true
        # select only when it's your stone
        if $("#main_board").data('this_player_id') == $(this).data('player_id')
          x = $(this).data('x')
          y = $(this).data('y')
          select_stone(x, y)

  select_stone = (x, y) ->
    $(".match_stone[data-x='" + x + "'][data-y='" + y + "']").css('border', '2px solid red')
    selected_stone = {x: x, y: y}
    console.log("Selecting stone at x = #{x}; y = #{y}...")

  deselect_stone = ->
    $(".match_stone").css('border', '')
    selected_stone = null
    console.log("Deselecting current stone...")

App.match = App.cable.subscriptions.create "MatchChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    this.post_status("connected to ActionCable", 'server')

  disconnected: ->
    # Called when the subscription has been terminated by the server
    this.post_status("ciscnnected from ActionCable", 'server')

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    switch data['mode']
      when 'board_render' then this.render_board(JSON.parse(data['board_data']), JSON.parse(data['signups']), data['message'], data['currently_playing'], data['target'])
      else alert 'unknown action received: ' + data['mode']

  play: (sourceX, sourceY, targetX, targetY) ->
    this.post_status("trying to move from #{sourceX}, #{sourceY} to #{targetX}, #{targetY}", 'client')
    @perform 'play', sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY

  refresh: ->
    this.post_status("requesting board reload", 'client')
    @perform 'refresh'

  give_up: ->
    @perform 'give_up'

  repopulate: ->
    @perform 'repopulate'

  
  render_board: (data, signups, message, currently_playing_id, target) ->
    #if target == -1
       #new Audio('http://adis.g6.cz/johncena/traitor.mp3').play()
    if target == -1 || target == $("#main_board").data('this_player_id')
      if App.players.ready()
        currently_playing_bar = $("#currently_playing_bar")
        currently_playing_bar.empty()
        currently_playing_bar.text("current player: #{App.players.find_by_id(currently_playing_id).name}")
        points_bar = $("#match_current_points")
        points_bar.empty()
        for signup in signups
          name_element = document.createElement("span")
          name_element.innerHTML = App.players.find_by_id(signup.player_id).name
          points_element = document.createElement("span")
          points_element.innerHTML = " spent: " + signup.spent_points
          player_element = document.createElement("div")
          player_element.appendChild(name_element)
          player_element.appendChild(points_element)
          points_bar.append(player_element)
        renderer = new App.shapes.MatchRenderer($("#main_board"))
        renderer.render(data)
        this.post_status(message, 'server')
        if currently_playing_id == $("#main_board").data('this_player_id')
          this.setup_stone_handlers()
      else
        App.players.get (players) =>
          this.render_board(data, signups, message, currently_playing_id, board_changed)

  post_status: (status, side) ->
    if status != ""
      current_date = new Date();
      message = "[#{side}] #{status} #{current_date.getHours()}:#{current_date.getMinutes()}:#{current_date.getSeconds()}"
      console.log(message)
      $('#status_bar').text(message)

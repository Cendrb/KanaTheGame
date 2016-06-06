$ ->
  $("h1").on 'click', (event) ->
    App.match.refresh()

  selected_stone = null
  stone_being_clicked = false

  $("#main_board").on 'click', (event) ->
    if !stone_being_clicked && selected_stone
      console.log("======CLICKED ON BOARD======")
      # board absolute location
      boardAbsoluteX = $(this).offset().left
      boardAbsoluteY = $(this).offset().top
      #console.log("Absolutes x = #{boardAbsoluteX}; y = #{boardAbsoluteY}")

      # click relative position
      clickRelativeToBoardX = event.pageX - boardAbsoluteX
      clickRelativeToBoardY = event.pageY - boardAbsoluteY
      #console.log("Relatives x = #{clickRelativeToBoardX}; y = #{clickRelativeToBoardY}")

      # click stone coords
      xStoneCoord = Math.floor(clickRelativeToBoardX / 50)
      yStoneCoord = Math.floor(clickRelativeToBoardY / 50)
      #console.log("Coords x = #{xStoneCoord}; y = #{yStoneCoord}")

      App.match.play(selected_stone.x, selected_stone.y, xStoneCoord, yStoneCoord)
      deselect_stone()
    stone_being_clicked = false

  App.match.setup_stone_handlers = ->
    $(".match_stone").on 'click', (event) ->
      if !selected_stone
        console.log("======CLICKED ON STONE======")
        stone_being_clicked = true
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
    console.log("Connected to ActionCable")

  disconnected: ->
    # Called when the subscription has been terminated by the server
    console.log("Discnnected from ActionCable")

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    console.log(data)
    switch data['mode']
      when 'board_render' then this.render_board(JSON.parse(data['board_data']), JSON.parse(data['current_points']))
      else alert 'unknown action received: ' + data['mode']

  play: (sourceX, sourceY, targetX, targetY) ->
    console.log("Trying to move from #{sourceX}, #{sourceY} to #{targetX}, #{targetY}")
    @perform 'play', sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY

  refresh: ->
    console.log("Requesting board reload")
    @perform 'refresh'

  give_up: ->
    @perform 'give_up'

  
  render_board: (data, signups) ->
    if App.players.ready()
      console.log(signups)
      points_bar = $("#match_current_points")
      points_bar.empty()
      for signup in signups
        name_element = document.createElement("span")
        name_element.innerHTML = App.players.find_by_id(signup.id).name
        points_element = document.createElement("span")
        points_element.innerHTML = signup.current_points
        player_element = document.createElement("div")
        player_element.appendChild(name_element)
        player_element.appendChild(points_element)
        points_bar.append(player_element)
      renderer = new App.shapes.MatchRenderer($("#main_board"))
      renderer.render(data)
      this.setup_stone_handlers()
    else
      App.players.get (players) =>
        this.render_board(data, signups)

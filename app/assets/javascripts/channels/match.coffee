$ ->
  if $("#main_board").length
    element_main_board = $("#main_board")
    element_player_mode = $("#mode")
    element_match_state = $('#state')
    element_player_name_and_color = $('#this_player')
    element_currently_playing = $("#currently_playing_bar")
    element_points_table = $("#match_current_points")
    element_status_bar = $("#status_bar")

    App.match = App.cable.subscriptions.create "MatchChannel",
      connected: ->
        # Called when the subscription is ready for use on the server
        this.post_status("connected to ActionCable", 'server')
        this.renderer = new App.shapes.MatchRenderer(element_main_board)

      disconnected: ->
        # Called when the subscription has been terminated by the server
        this.post_status("disconnected from ActionCable", 'server')

      received: (data) ->
        # Called when there's incoming data on the websocket for this channel
        switch data['mode']
          when 'set_state'
            App.match.state = data['state']
            this.post_status('CURRENT STATE: ' + data['state'], 'server')
            element_match_state.text(data['state'])

            # update connected users
            this.update_connected_users(JSON.parse(data['signups']))

          when 'set_mode'
            if element_main_board.data('current_user_id') == data['target_user_id']
              this.post_status("setting mode #{data['player_mode']} for user #{data['target_user_id']} playing as #{data['player_id']}", 'server')
              App.match.mode = data['player_mode']
              App.match.player_id = data['player_id']
              element_player_mode.text(data['player_mode'])

              App.Players.run_when_ready (players_unused) =>
                player_object = App.Players.find_by_id(data['player_id'])
                if (player_object != null)
                  element_player_name_and_color.text(player_object.name)
                  element_player_name_and_color.css('color', player_object.color)
                else
                  element_player_name_and_color.text('just a spectator')
          when 'board_render'
            console.log(data)
            this.render_board(
              JSON.parse(data['board_data']),
              JSON.parse(data['fulfilled_shapes']),
              JSON.parse(data['signups']),
              data['message'],
              data['currently_playing'],
              data['target_user_id'])
          else alert 'unknown action received: ' + data['mode']

      play: (sourceX, sourceY, targetX, targetY) ->
        this.post_status("trying to move from #{sourceX}, #{sourceY} to #{targetX}, #{targetY}", 'client')
        @perform 'play', { sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY }

      refresh: ->
        this.post_status("requesting board reload", 'client')
        @perform 'refresh'

      repopulate: ->
        @perform 'repopulate'

      trade_shape: (fulfilled_shape_id) ->
        this.post_status("submitting shape #{fulfilled_shape_id} for trade", 'client')
        @perform 'trade_shape', { id: fulfilled_shape_id }

      render_board: (data, fulfilled_shapes, signups, message, currently_playing_id, target) ->
        # target = -1 => information for everyone, otherwise player id
        App.match.currently_playing_player_id = currently_playing_id
        if target == -1 || target == element_main_board.data('current_user_id')
          App.Players.run_when_ready (players) =>
            element_currently_playing.empty()
            element_currently_playing.text("current player: #{App.Players.find_by_id(currently_playing_id).name}")
            element_points_table.empty()
            for signup in signups
              traded_shapes = fulfilled_shapes.filter((s) -> s.traded && s.player_id == signup.player_id)
              console.log(traded_shapes)
              name_element = document.createElement("span")
              name_element.innerHTML = App.Players.find_by_id(signup.player_id).name
              points_element = document.createElement("span")
              reducer_func = (acc, s) -> acc + s.points
              points_total = traded_shapes.reduce(reducer_func, 0)
              points_element.innerHTML = " spent: #{signup.spent_points}, earned: #{points_total} - #{traded_shapes.map((s) -> "#{s.name} (#{s.points})").join(", ")}"
              player_element = document.createElement("div")
              player_element.appendChild(name_element)
              player_element.appendChild(points_element)
              element_points_table.append(player_element)
            this.renderer.render(data, fulfilled_shapes)
            this.post_status('board changed: ' + message, 'server')
            if App.match.state == 'playing' && App.match.mode == 'play' && currently_playing_id == App.match.player_id
              this.setup_stone_handlers()

      post_status: (status, side) ->
        if status != ""
          current_date = new Date();
          message = "[#{side}] #{status} @#{current_date.toLocaleTimeString("cs-cs")}"
          console.log(message)
          element_status_bar.text(message)

      update_connected_users: (signups) ->
        App.Players.run_when_ready (players) =>
          connected_players = $("#connected_users")
          connected_players.empty()
          for signup in signups
            user_name_element = document.createElement("span")
            user_name_element.innerHTML = signup.user_name
            as_text_element = document.createElement("span")
            as_text_element.innerHTML = " playing as "
            player = App.Players.find_by_id(signup.player_id)
            player_name_element = document.createElement("span")
            player_name_element.innerHTML = player.name
            player_name_element.style.color = player.color
            player_element = document.createElement("div")
            player_element.appendChild(user_name_element)
            player_element.appendChild(as_text_element)
            player_element.appendChild(player_name_element)
            connected_players.append(player_element)

    $("h1").on 'click', (event) ->
      App.match.refresh()

    $("#repopulate_board").on 'click', (event) ->
      App.match.repopulate()

    selected_stone = null
    stone_being_clicked = false

    element_main_board.on 'click', (event) ->
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
      $(".match_stone").off('click')
      $(".match_stone").on 'click', (event) ->
        if !selected_stone
          console.log("======CLICKED ON STONE======")
          console.log(this)
          console.log(this.dataset.player_id)
          console.log(App.match.player_id)
          console.log(parseInt(this.dataset.player_id) == App.match.player_id)
          stone_being_clicked = true
          # select only when it's your stone and you are not a spectator AND you are the player which is currently playing
          if App.match.currently_playing_player_id == App.match.player_id && App.match.player_id != -1 && App.match.player_id == parseInt(this.dataset.player_id)
            x = parseInt(this.dataset.x)
            y = parseInt(this.dataset.y)
            select_stone(x, y)
      $(".fulfilled_shape").off('click')
      $(".fulfilled_shape").on 'click', (event) ->
        console.log("======CLICKED ON SHAPE======")
        if App.match.currently_playing_player_id == App.match.player_id && App.match.player_id != -1 && App.match.player_id == parseInt(this.dataset.player_id)
          App.match.trade_shape(parseInt(this.dataset.id))

    select_stone = (x, y) ->
      $(".match_stone[data-x='#{x}'][data-y='#{y}']").css('border', '2px solid red')
      selected_stone = {x: x, y: y}
      console.log("Selecting stone at x = #{x}; y = #{y}...")

    deselect_stone = ->
      $(".match_stone").css('border', '')
      selected_stone = null
      console.log("Deselecting current stone...")

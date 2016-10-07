App.Players = class Players
  @_currently_loading = false
  @_onloaded_callbacks = []
  @_players = null

  @run_when_ready: (callback) ->
    if @_players
      callback(@_players)
    else
      if @_currently_loading
        @_onloaded_callbacks.push(callback)
      else
        @_currently_loading = true
        @_onloaded_callbacks.push(callback)
        $.getJSON "/players.json", (data) =>
          @_players = data
          for onloaded_callback in @_onloaded_callbacks
            onloaded_callback(@_players)

  @find_by_id: (id) ->
    players_array = (@_players.filter (obj) ->
      return obj.id == id)
    if players_array.length > 0
      return players_array[0]
    else
      return null
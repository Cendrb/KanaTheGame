App.players.currently_loading = false
App.players.onloaded_callbacks = []

App.players.get = (callback) ->
  if App.players._players
    callback(App.players._players)
    return App.players._players
  else
    if App.players.currently_loading
      App.players.onloaded_callbacks.push(callback)
    else
      App.players.currently_loading = true
      App.players.onloaded_callbacks.push(callback)
      $.getJSON "/players.json", (data) =>
        App.players._players = data
        for onloaded_callback in App.players.onloaded_callbacks
          onloaded_callback(App.players._players)
App.players.ready = ->
  if App.players._players
    return true
  else
    return false
  
App.players.find_by_id = (id) ->
  players_array = (App.players._players.filter (obj) ->
    return obj.id == id)
  if players_array.length > 0
    return players_array[0]
  else
    return null
  
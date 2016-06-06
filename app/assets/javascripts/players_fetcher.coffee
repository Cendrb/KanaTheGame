App.players.get = (callback) ->
  if App.players._players
    if callback
      callback(App.players._players)
    return App.players._players
  else
    $.getJSON "/players.json", (data) =>
      App.players._players = data
      if callback
        callback(App.players._players)
App.players.ready = ->
  if App.players._players
    return true
  else
    return false
  
App.players.find_by_id = (id) ->
  player = (App.players._players.filter (obj) ->
    return obj.id == id)[0]
  return player
  
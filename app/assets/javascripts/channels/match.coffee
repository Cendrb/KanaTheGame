$ ->
  selection_mode = 'nothing'

  $("h1").on 'click', (event) ->
    App.match.give_up()

  $("#main_board").on 'click', (event) ->
    if selection_mode == SelectionMode.stone_selected
      console.log('Try a move')

  $(".match_stone").on 'click', (event) ->
    if selection_mode == SelectionMode.nothing
      console.log('Select a stone')
    if selection_mode == SelectionMode.stone_selected
      console.log('Try a move while swaping')

class SelectionMode
  @nothing: 'nothing'
  @stone_selected: 'stone_selected'

App.match = App.cable.subscriptions.create "MatchChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    console.log("Connected to ActionCable")

  disconnected: ->
    # Called when the subscription has been terminated by the server
    console.log("Discnnected from ActionCable")

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    console.log("Received: " + data)
    switch data['mode']
      when 'board_render' then this.render_board(data['board_data'])
      else alert 'unknown action received: ' + data['mode']

  select: ->
    @perform 'select'

  play: ->
    @perform 'play'

  give_up: ->
    @perform 'give_up'
    
  
  render_board: (data) ->
    console.log("Invoked render_board")
    renderer = new App.shapes.MatchRenderer($("#main_board"))
    renderer.render(JSON.parse(data))

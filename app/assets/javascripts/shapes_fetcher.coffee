App.shapes.get = (callback) ->
  if App.shapes._shapes
    callback(App.shapes._shapes)
  else
    $.getJSON "/shapes.json", (data) =>
      App.shapes._shapes = data
      callback(App.shapes._shapes)

App.shapes.find_by_id = (id) ->
  shapes_array = (App.shapes._shapes.filter (obj) ->
    return obj.id == id)
  if shapes_array.length > 0
    return shapes_array[0]
  else
    return null

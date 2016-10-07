App.shapes.Shapes = class Shapes
  @_currently_loading = false
  @_onloaded_callbacks = []
  @_shapes = null

  @run_when_ready: (callback) ->
    if @_shapes
      callback(@_shapes)
    else
      if @_currently_loading
        @_onloaded_callbacks.push(callback)
      else
        @_currently_loading = true
        @_onloaded_callbacks.push(callback)
        $.getJSON "/shapes.json", (data) =>
          @_shapes = data
          for onloaded_callback in @_onloaded_callbacks
            onloaded_callback(@_shapes)

  @find_by_id: (id) ->
    shapes_array = (@_shapes.filter (obj) ->
      return obj.id == id)
    if shapes_array.length > 0
      return shapes_array[0]
    else
      return null

json.array!(@shapes) do |shape|
  json.extract! shape, :id, :name, :points, :board_data
  json.url shape_url(shape, format: :json)
end

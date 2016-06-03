json.array!(@players) do |player|
  json.extract! player, :id, :name, :priority, :color
  json.url player_url(player, format: :json)
end

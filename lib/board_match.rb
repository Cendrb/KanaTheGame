class BoardMatch < Board
  attr_reader :width, :height

  def initialize(width, height)
    super()
    @width, @height = width.to_i, height.to_i
  end

  def add_stone_at(x, y, player_id)
    _add_stone_at(x, y, StoneMatch.new(player_id))
  end

  def self.load(json)
    unless json.nil?
      attrs = JSON.parse(json)
      obj = self.new(attrs['width'], attrs['height'])
      attrs['stones'].each do |stone|
        obj.add_stone_at(stone['x'], stone['y'], stone['player_id'])
      end
    end
    return obj
  end

  def self.dump(obj)
    if obj
      final_array = []
      obj.each_stone(->(x, y, stone) { final_array << {x: x, y: y, player_id: stone.player_id } })
      final_hash = {stones: final_array, width: obj.width, height: obj.height}
      return final_hash.to_json
    end
  end
end
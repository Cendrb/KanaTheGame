class BoardFulfilledShape < Board
  def set_stone_at(x, y, player_id)
    _set_stone_at(x, y, StoneFulfilledShape.new(player_id))
  end

  def BoardFulfilledShape.load(json)
    unless json.nil?
      attrs = JSON.parse(json)
      obj = self.new
      attrs['stones'].each do |stone|
        obj.set_stone_at(stone['x'], stone['y'], stone['player_id'])
      end
    end
    return obj
  end

  def BoardFulfilledShape.dump(obj)
    if obj
      final_array = []
      obj.each_stone { |x, y, stone| final_array << {x: x, y: y, player_id: stone.player_id} }
      final_hash = {stones: final_array}
      return final_hash.to_json
    end
  end
end

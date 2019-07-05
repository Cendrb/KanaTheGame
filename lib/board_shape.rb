class BoardShape < Board
  def initialize
    super()
  end

  def add_stone_at(x, y, stone_owner_flag)
    _set_stone_at(x, y, StoneShape.new(stone_owner_flag))
  end

  def self.load(json)
    obj = self.new
    unless json.nil?
      attrs = JSON.parse(json)
      attrs['stones'].each do |stone|
        obj.add_stone_at(stone['x'], stone['y'], stone['stone_owner_flag'])
      end
    end
    return obj
  end

  def self.dump(obj)
    if obj
      final_array = []
      obj.each_stone{ |x, y, stone| final_array << {x: x, y: y, stone_owner_flag: stone.stone_owner_flag} }
      final_hash = {stones: final_array}
      return final_hash.to_json
    end
  end

  def to_s
    return BoardShape.dump(self)
  end
end

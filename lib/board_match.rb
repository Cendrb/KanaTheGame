class BoardMatch < Board
  attr_accessor :width, :height

  def initialize
    super()
    @width, @height = 0, 0
    @last_stone_id_assigned = 0
  end

  def perform_move(source_x, source_y, target_x, target_y, sender_player_id, currently_playing_id)
    # check if move is technically possible
    x_diff = (source_x - target_x)
    y_diff = (source_y - target_y)
    x_abs_diff = x_diff.abs
    y_abs_diff = y_diff.abs

    if sender_player_id != currently_playing_id
      return :invalid, 'it is not your turn yet, wait for others to play'
    end

    if x_abs_diff + y_abs_diff == 1
      # horizontal/vertical move
      mode = :horizontal_vertical
    elsif x_abs_diff == 1 && y_abs_diff == 1
      # diagonal move
      mode = :diagonal
    elsif x_abs_diff + y_abs_diff == 2
      # special over-fuck-move
      mode = :over_jump
    else
      # invalid
      return :invalid, 'move not in range'
    end

    if mode != :invalid
      source_stone = get_stone_at(source_x, source_y)
      if source_stone && source_stone.player_id == sender_player_id # exists and is a property of current player
        if mode == :over_jump
          over_jumped_x = source_x - (x_diff / 2)
          over_jumped_y = source_y - (y_diff / 2)
          over_jumped_stone = get_stone_at(over_jumped_x, over_jumped_y)
          if over_jumped_stone
            remove_stone_at(over_jumped_x, over_jumped_y)
          else
            return :invalid, 'over-jump cannot by done without something to jump over'
          end
        end
        target_stone = get_stone_at(target_x, target_y)
        if target_stone # if target exists
          if target_stone.player_id == -1 # if target stone is immovable
            return :invalid, 'you cannot swap with immovable stones'
          end
          _set_stone_at(source_x, source_y, target_stone)
          _set_stone_at(target_x, target_y, source_stone)
        else
          _set_stone_at(target_x, target_y, source_stone)
          remove_stone_at(source_x, source_y)
        end
      else
        return :invalid, 'you cannot move other peoples stones'
      end
    end
    return mode, 'move successful'
  end

  def trade_shape(fulfilled_shape)
    fulfilled_shape.board_data.each_stone do |x, y, stone|
      remove_stone_at x, y
    end
  end

  def set_stone_at(id, x, y, player_id)
    _set_stone_at(x, y, StoneMatch.new(id, player_id))
  end

  def repopulate(player_ids, remove_old_stones = true)
    if remove_old_stones
      remove_all_stones
      @last_stone_id_assigned = 0
    end
    randomizer = Random.new
    total_stones = (@width * @height) / 3
    stones_per_player = total_stones / player_ids.count
    player_ids.each do |player_id|
      stones_per_player.times do
        x = 0
        y = 0
        loop do
          x = randomizer.rand(0..(@width - 1))
          y = randomizer.rand(0..(@height - 1))
          break if !exists_at?(x, y)
        end
        @last_stone_id_assigned += 1
        set_stone_at(@last_stone_id_assigned, x, y, player_id)
      end
    end
  end

  def each_spot(proc)
    (0..(width - 1)).each { |x|
      (0..(height - 1)).each { |y|
        proc.call(x, y)
      }
    }
  end

  def BoardMatch.load(json)
    unless json.nil?
      attrs = JSON.parse(json)
      obj = self.new
      obj.width = attrs['width'].to_i
      obj.height = attrs['height'].to_i
      attrs['stones'].each do |stone|
        obj.set_stone_at(stone['id'], stone['x'], stone['y'], stone['player_id'])
      end
    end
    return obj
  end

  def BoardMatch.dump(obj)
    if obj
      final_array = []
      obj.each_stone { |x, y, stone| final_array << {id: stone.id, x: x, y: y, player_id: stone.player_id} }
      final_hash = {stones: final_array, width: obj.width, height: obj.height}
      return final_hash.to_json
    end
  end
end

class Board
  def initialize
    @board_hash = Hash.new
  end

  def each_stone(proc)
    @board_hash.each do |key, value|
      proc.call(key[0], key[1], value)
    end
  end

  def get_stone_at(x, y)
    return @board_hash[[x, y]]
  end

  def exists_at?(x, y)
    return @board_hash[[x, y]]!= nil
  end

  protected
  def _set_stone_at(x, y, stone)
    @board_hash[[x, y]] = stone
  end

  protected
  def remove_stone_at(x, y)
    if @board_hash.key?([x, y])
      @board_hash.delete([x, y])
    end
  end

  protected
  def remove_all_stones
    @board_hash = Hash.new
  end
end
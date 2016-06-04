class Board
  def initialize
    @board_hash = Hash.new
  end

  def each_stone(proc)
    @board_hash.each do |key, value|
      proc.call(key[0], key[1], value)
    end
  end

  protected
  def _add_stone_at(x, y, stone)
    @board_hash[[x, y]] = stone
  end
end
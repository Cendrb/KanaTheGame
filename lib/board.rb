class Board
  def initialize
    @board_hash = Hash.new
  end

  def each_stone
    @board_hash.each do |key, value|
      yield(key[0], key[1], value)
    end
  end

  def get_stone_at(x, y)
    return @board_hash[[x, y]]
  end

  def exists_at?(x, y)
    return @board_hash[[x, y]]!= nil
  end

  def ==(other_board)
    return false if other_board.nil?
    other_board.same_data? @board_hash
  end

  def new_translate(x, y)
    new_vertices = @board_hash.map do |key, value|
      [ [key[0] + x, key[1] + y], value ]
    end
    board = self.class.new
    new_vertices.each { |key, value| board._set_stone_at key[0], key[1], value }
    return board
  end

  def new_rotated
    # multiply all vertices by the rotation matrix
    new_vertices = @board_hash.map do |key, value|
      # multiply by the following matrix (90 degress clockwise)
      #  0 1
      # -1 0
      x = key[0] * 0 + key[1] * -1
      y = key[0] * 1 + key[1] * 0

      [ [x, y], value ]
    end

    # find the min for each dimension and translate the shape to make all coordinates positive
    x_offset = new_vertices.min { |a, b| a[0][0] <=> b[0][0] } [0][0] . abs
    y_offset = new_vertices.min { |a, b| a[0][1] <=> b[0][1] } [0][1] . abs

    board = self.class.new
    new_vertices.each { |key, value| board._set_stone_at x_offset+key[0], y_offset+key[1], value }
    return board
  end

  protected
  def same_data?(other_data)
    @board_hash == other_data
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

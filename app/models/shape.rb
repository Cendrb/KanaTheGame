class Shape < ApplicationRecord
  has_many :fulfilled_shapes
  after_find :create_variants
  serialize :board_data, BoardShape

  def serializable_hash(options)
    return {id: self.id, name: self.name, points: self.points, variants: @variants.map(&:to_s) }
  end

  def create_variants
    @variants = []
    @variants << board_data
    
    new_board = board_data
    3.times do
      new_board = new_board.new_rotated
      @variants << new_board unless @variants.include? new_board
    end
  end

  def get_shapes_in_match(match, player_id)
    shapes = []
    match.board_data.each_stone do |x, y, stone|
      @variants.each do |variant|
        fulfilled_shape = variant_satisfies(x, y, match.board_data, variant, player_id)
        if fulfilled_shape
          shapes << FulfilledShape.new(shape: self, board_data: fulfilled_shape, player_id: player_id, match: match)
        end
      end
    end
    return shapes
  end

  def variant_satisfies(x, y, board, variant, player_id)
    fulfilled_shape = BoardFulfilledShape.new
    variant.each_stone do |variant_x, variant_y, variant_stone|
      stone = board.get_stone_at(variant_x + x, variant_y + y)
      mine, other_players, neutrals = StoneOwnerAcceptedFlag.parse_flag(variant_stone.stone_owner_flag)
      return nil unless stone
      return nil if !mine and stone.player_id == player_id
      return nil if !other_players and stone.player_id != player_id
      return nil if !neutrals and stone.player_id == -1
      fulfilled_shape.set_stone_at(stone.id, variant_x + x, variant_y + y, stone.player_id)
    end
    return fulfilled_shape
  end
end

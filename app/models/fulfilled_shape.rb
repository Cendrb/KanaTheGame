class FulfilledShape < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :shape
  serialize :board_data, BoardFulfilledShape

  def serializable_hash(options)
    return {id: self.id, player_id: self.player_id, color: self.player.color, name: self.shape.name, points: self.shape.points, traded: self.traded, board_data: BoardFulfilledShape.dump(self.board_data)}
  end

  validates_presence_of :match, :player, :shape
end

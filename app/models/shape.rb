class Shape < ApplicationRecord
  has_many :fulfilled_shapes
  serialize :board_data, BoardShape

  def serializable_hash(options)
    return {id: self.id, name: self.name, points: self.points, board_data: self.attributes_before_type_cast['board_data'] }
  end
end

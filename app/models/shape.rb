class Shape < ApplicationRecord
  has_many :fulfilled_shapes
  serialize :board_data, BoardShape
end

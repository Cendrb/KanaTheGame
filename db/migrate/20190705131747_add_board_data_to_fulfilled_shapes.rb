class AddBoardDataToFulfilledShapes < ActiveRecord::Migration[5.0]
  def change
    add_column :fulfilled_shapes, :board_data, :text
  end
end

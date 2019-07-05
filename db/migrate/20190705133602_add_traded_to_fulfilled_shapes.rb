class AddTradedToFulfilledShapes < ActiveRecord::Migration[5.0]
  def change
    add_column :fulfilled_shapes, :traded, :boolean, null: false, default: false
  end
end

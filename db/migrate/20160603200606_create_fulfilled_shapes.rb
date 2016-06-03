class CreateFulfilledShapes < ActiveRecord::Migration[5.0]
  def change
    create_table :fulfilled_shapes do |t|
      t.integer :shape_id
      t.integer :match_id
      t.integer :player_id

      t.timestamps
    end
  end
end

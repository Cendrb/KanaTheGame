class CreateShapes < ActiveRecord::Migration[5.0]
  def change
    create_table :shapes do |t|
      t.string :name
      t.integer :points
      t.text :board_data

      t.timestamps
    end
  end
end

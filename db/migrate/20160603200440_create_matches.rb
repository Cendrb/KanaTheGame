class CreateMatches < ActiveRecord::Migration[5.0]
  def change
    create_table :matches do |t|
      t.text :board_data
      t.integer :height
      t.integer :width
      t.boolean :started
      t.datetime :started_on
      t.datetime :ended_on

      t.timestamps
    end
  end
end

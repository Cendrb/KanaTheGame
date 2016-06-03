class CreateMatchSignups < ActiveRecord::Migration[5.0]
  def change
    create_table :match_signups do |t|
      t.integer :user_id
      t.integer :match_id
      t.integer :player_id

      t.timestamps
    end
  end
end

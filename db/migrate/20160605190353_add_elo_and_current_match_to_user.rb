class AddEloAndCurrentMatchToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :elo, :integer
    add_column :users, :current_match_id, :integer
  end
end

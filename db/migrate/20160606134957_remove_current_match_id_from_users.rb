class RemoveCurrentMatchIdFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :current_match_id, :integer
  end
end

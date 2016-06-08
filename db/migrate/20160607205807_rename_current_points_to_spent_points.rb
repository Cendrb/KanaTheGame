class RenameCurrentPointsToSpentPoints < ActiveRecord::Migration[5.0]
  def change
    rename_column :match_signups, :current_points, :spent_points
  end
end

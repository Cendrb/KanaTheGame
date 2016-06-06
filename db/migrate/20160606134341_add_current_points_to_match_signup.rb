class AddCurrentPointsToMatchSignup < ActiveRecord::Migration[5.0]
  def change
    add_column :match_signups, :current_points, :integer
  end
end

class ChangeInMatches < ActiveRecord::Migration[5.0]
  def change
    remove_column :matches, :started, :boolean
    remove_column :matches, :started_on, :datetime
    remove_column :matches, :ended_on, :datetime
    add_column :matches, :state, :integer, default: 0
    add_column :matches, :finished_on, :datetime
  end
end

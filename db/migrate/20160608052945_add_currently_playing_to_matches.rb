class AddCurrentlyPlayingToMatches < ActiveRecord::Migration[5.0]
  def change
    add_column :matches, :currently_playing, :integer
  end
end

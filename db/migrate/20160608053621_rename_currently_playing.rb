class RenameCurrentlyPlaying < ActiveRecord::Migration[5.0]
  def change
    rename_column :matches, :currently_playing, :currently_playing_id
  end
end

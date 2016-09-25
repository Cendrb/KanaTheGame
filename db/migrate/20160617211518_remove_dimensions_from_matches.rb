class RemoveDimensionsFromMatches < ActiveRecord::Migration[5.0]
  def change
    remove_column :matches, :height, :integer
    remove_column :matches, :width, :integer
  end
end

class AddTypeToMatches < ActiveRecord::Migration[5.0]
  def change
    add_column :matches, :type, :integer
    add_column :matches, :password, :string
  end
end

class AddSurrenderedToMatchSignups < ActiveRecord::Migration[5.0]
  def change
    add_column :match_signups, :lost, :boolean, null: false, default: false
  end
end

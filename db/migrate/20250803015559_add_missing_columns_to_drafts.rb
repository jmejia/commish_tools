class AddMissingColumnsToDrafts < ActiveRecord::Migration[8.0]
  def change
    add_column :drafts, :draft_type, :integer
    add_column :drafts, :league_size, :integer
  end
end

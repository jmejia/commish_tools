class AddSleeperFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sleeper_username, :string
    add_column :users, :sleeper_id, :string
  end
end

class CreateSleeperConnectionRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_connection_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :sleeper_username, null: false
      t.string :sleeper_id, null: false
      t.integer :status, default: 0, null: false # enum: pending: 0, approved: 1, rejected: 2
      t.timestamp :requested_at, null: false
      t.timestamp :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.text :rejection_reason

      t.timestamps
    end
    
    add_index :sleeper_connection_requests, :status
  end
end

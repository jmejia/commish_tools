class CreateSchedulingPolls < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduling_polls do |t|
      t.bigint :league_id, null: false
      t.bigint :created_by_id, null: false
      t.string :public_token, null: false
      t.string :event_type, null: false, default: 'draft'
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.datetime :closes_at
      t.jsonb :settings, default: {}
      t.jsonb :event_metadata, default: {}

      t.timestamps
    end

    add_index :scheduling_polls, :league_id
    add_index :scheduling_polls, :created_by_id
    add_index :scheduling_polls, :public_token, unique: true
    add_index :scheduling_polls, :status
    add_index :scheduling_polls, :event_type
    add_index :scheduling_polls, [:league_id, :event_type]

    add_foreign_key :scheduling_polls, :leagues
    add_foreign_key :scheduling_polls, :users, column: :created_by_id
  end
end

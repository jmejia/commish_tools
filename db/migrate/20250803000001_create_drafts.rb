class CreateDrafts < ActiveRecord::Migration[8.0]
  def change
    create_table :drafts do |t|
      t.references :league, null: false, foreign_key: true
      t.string :sleeper_draft_id, null: false
      t.string :season_year, null: false
      t.string :status, null: false
      t.jsonb :settings, default: {}
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :drafts, :sleeper_draft_id, unique: true
    add_index :drafts, [:league_id, :season_year]
    add_index :drafts, :status
    add_index :drafts, :completed_at
    add_index :drafts, :settings, using: :gin
  end
end
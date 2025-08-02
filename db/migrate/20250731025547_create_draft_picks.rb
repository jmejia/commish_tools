class CreateDraftPicks < ActiveRecord::Migration[8.0]
  def change
    create_table :draft_picks do |t|
      t.references :draft, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :sleeper_player_id, null: false
      t.string :sleeper_user_id, null: false
      t.integer :round, null: false
      t.integer :pick_number, null: false
      t.integer :overall_pick, null: false
      t.string :player_name
      t.string :position
      t.decimal :adp, precision: 5, scale: 2
      t.decimal :projected_points, precision: 8, scale: 2
      t.decimal :value_over_replacement, precision: 8, scale: 2
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :draft_picks, [:draft_id, :overall_pick], unique: true
    add_index :draft_picks, [:draft_id, :user_id]
    add_index :draft_picks, :sleeper_player_id
    add_index :draft_picks, :position
    add_index :draft_picks, :metadata, using: :gin
  end
end

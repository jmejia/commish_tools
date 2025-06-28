class CreatePressConferences < ActiveRecord::Migration[8.0]
  def change
    create_table :press_conferences do |t|
      t.references :league, null: false, foreign_key: true
      t.references :target_manager, null: false, foreign_key: { to_table: :league_memberships }
      t.integer :week_number
      t.integer :season_year
      t.integer :status
      t.jsonb :context_data

      t.timestamps
    end
  end
end

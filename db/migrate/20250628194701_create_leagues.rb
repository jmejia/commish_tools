class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |t|
      t.string :sleeper_league_id
      t.string :name
      t.integer :season_year
      t.jsonb :settings
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :leagues, :sleeper_league_id, unique: true
  end
end

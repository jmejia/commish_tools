class CreateLeagueContexts < ActiveRecord::Migration[8.0]
  def change
    create_table :league_contexts do |t|
      t.references :league, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end

    add_index :league_contexts, :league_id, unique: true, if_not_exists: true
  end
end
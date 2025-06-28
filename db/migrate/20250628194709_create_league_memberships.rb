class CreateLeagueMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :league_memberships do |t|
      t.references :league, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :sleeper_user_id
      t.string :team_name
      t.integer :role

      t.timestamps
    end
  end
end

class CreateDraftGrades < ActiveRecord::Migration[8.0]
  def change
    create_table :draft_grades do |t|
      t.references :league, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :draft, null: false, foreign_key: true
      t.string :grade, null: false
      t.integer :projected_rank, null: false
      t.decimal :projected_points, precision: 10, scale: 2
      t.decimal :projected_wins, precision: 4, scale: 2
      t.decimal :playoff_probability, precision: 5, scale: 2
      t.jsonb :position_grades, default: {}
      t.jsonb :best_picks, default: []
      t.jsonb :worst_picks, default: []
      t.jsonb :analysis, default: {}
      t.datetime :calculated_at

      t.timestamps
    end

    add_index :draft_grades, [:league_id, :user_id, :draft_id], unique: true
    add_index :draft_grades, [:league_id, :projected_rank]
    add_index :draft_grades, :grade
    add_index :draft_grades, :calculated_at
    add_index :draft_grades, :position_grades, using: :gin
    add_index :draft_grades, :analysis, using: :gin
  end
end

class AddDraftReferenceToDraftGrades < ActiveRecord::Migration[8.0]
  def change
    # Add draft reference and performance indexes
    # The draft_grades table already exists but needs the draft reference
    unless column_exists?(:draft_grades, :draft_id)
      add_reference :draft_grades, :draft, null: true, foreign_key: true
    end
    
    # Rename column first if it exists
    if column_exists?(:draft_grades, :drafted_at)
      rename_column :draft_grades, :drafted_at, :calculated_at
    end
    
    # Add missing performance indexes if they don't exist
    unless index_exists?(:draft_grades, :position_grades)
      add_index :draft_grades, :position_grades, using: :gin
    end
    
    unless index_exists?(:draft_grades, :analysis)
      add_index :draft_grades, :analysis, using: :gin
    end
    
    unless index_exists?(:draft_grades, :calculated_at)
      add_index :draft_grades, :calculated_at
    end
    
    # Update unique index to include draft_id
    if index_exists?(:draft_grades, [:league_id, :user_id])
      remove_index :draft_grades, [:league_id, :user_id]
      add_index :draft_grades, [:league_id, :user_id, :draft_id], unique: true
    end
    
    unless index_exists?(:draft_grades, [:league_id, :projected_rank])
      add_index :draft_grades, [:league_id, :projected_rank]
    end
    
  end
end

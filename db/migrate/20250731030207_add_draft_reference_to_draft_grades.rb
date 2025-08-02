class AddDraftReferenceToDraftGrades < ActiveRecord::Migration[8.0]
  def change
    # The draft reference already exists in the base migration
    
    # Rename column first if it exists
    if column_exists?(:draft_grades, :drafted_at)
      rename_column :draft_grades, :drafted_at, :calculated_at
    end
    
    # Performance indexes already exist in the base migration
    
    # Unique index with draft_id already exists in the base migration
    
    # league_id, projected_rank index already exists in the base migration
    
  end
end

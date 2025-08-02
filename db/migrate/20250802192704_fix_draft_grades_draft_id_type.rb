class FixDraftGradesDraftIdType < ActiveRecord::Migration[8.0]
  def change
    # Change draft_id from string to bigint and add proper foreign key constraint
    change_column :draft_grades, :draft_id, :bigint
    add_foreign_key :draft_grades, :drafts, column: :draft_id
  end
end
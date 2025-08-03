class ChangeAdpToDecimalInDraftPicks < ActiveRecord::Migration[8.0]
  def change
    change_column :draft_picks, :adp, :decimal, precision: 5, scale: 1
  end
end

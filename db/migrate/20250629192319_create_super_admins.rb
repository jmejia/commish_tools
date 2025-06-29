class CreateSuperAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :super_admins do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end

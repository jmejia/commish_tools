class CreateVoiceUploadLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :voice_upload_links do |t|
      t.references :voice_clone, null: false, foreign_key: true
      t.string :public_token, null: false
      t.string :title
      t.text :instructions
      t.datetime :expires_at
      t.boolean :active, default: true, null: false
      t.integer :max_uploads, default: 1, null: false
      t.integer :upload_count, default: 0, null: false

      t.timestamps
    end
    add_index :voice_upload_links, :public_token, unique: true
  end
end

class CreateVoiceClones < ActiveRecord::Migration[8.0]
  def change
    create_table :voice_clones do |t|
      t.references :league_membership, null: false, foreign_key: true
      t.string :playht_voice_id
      t.string :original_audio_url
      t.integer :status
      t.string :upload_token

      t.timestamps
    end
  end
end

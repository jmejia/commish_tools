# Creates the voice clones table for AI-powered personalized press conferences.
# 
# This table stores voice clone data for generating custom audio responses in
# press conferences. Each league membership can have one voice clone. Key design decisions:
# 
# - Linked to league_membership: Voice clones are specific to user+league combinations
# - playht_voice_id: Identifier for the trained voice model in PlayHT's system
# - original_audio_url: Reference to the user's uploaded audio sample
# - status: Enum tracking clone creation progress (pending, processing, ready, failed)
# - upload_token: Secure token for managing the voice training workflow
# 
# This enables personalized AI-generated press conference responses using each
# user's actual voice, creating immersive fantasy football experiences.
class CreateVoiceClones < ActiveRecord::Migration[8.0]
  def change
    create_table :voice_clones do |voice_clones_table|
      voice_clones_table.references :league_membership, null: false, foreign_key: true
      voice_clones_table.string :playht_voice_id      # AI voice model ID from PlayHT
      voice_clones_table.string :original_audio_url   # User's uploaded voice sample
      voice_clones_table.integer :status              # Enum: pending, processing, ready, failed
      voice_clones_table.string :upload_token         # Secure workflow token

      voice_clones_table.timestamps
    end
  end
end

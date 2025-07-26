class AddAudioAttachmentsToModels < ActiveRecord::Migration[8.0]
  def change
    # Add final_audio_url for the complete press conference audio
    add_column :press_conferences, :final_audio_url, :string
  end
end
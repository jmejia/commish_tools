class CreatePressConferenceResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :press_conference_responses do |t|
      t.references :press_conference_question, null: false, foreign_key: true
      t.text :response_text
      t.string :response_audio_url
      t.text :generation_prompt

      t.timestamps
    end
  end
end

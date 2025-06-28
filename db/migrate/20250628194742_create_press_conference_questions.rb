class CreatePressConferenceQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :press_conference_questions do |t|
      t.references :press_conference, null: false, foreign_key: true
      t.text :question_text
      t.string :question_audio_url
      t.string :playht_question_voice_id
      t.integer :order_index

      t.timestamps
    end
  end
end

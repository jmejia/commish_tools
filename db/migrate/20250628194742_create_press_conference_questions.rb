# Creates the press conference questions table for AI-generated interview questions.
# 
# This table stores individual questions within each press conference, supporting
# both text and AI-generated audio versions. Key design decisions:
# 
# - press_conference: Each question belongs to a specific weekly press conference
# - question_text: The text version of the AI-generated question
# - question_audio_url: Generated audio of question using AI voice (sports reporter voice)
# - playht_question_voice_id: Specific AI voice used for asking questions (interviewer persona)
# - order_index: Sequence order for questions within the press conference
# 
# This allows creating structured interviews with AI-generated questions delivered
# in a professional sports reporter voice, creating authentic press conference experiences.
class CreatePressConferenceQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :press_conference_questions do |questions_table|
      questions_table.references :press_conference, null: false, foreign_key: true
      questions_table.text :question_text              # AI-generated question text
      questions_table.string :question_audio_url       # Audio version of question
      questions_table.string :playht_question_voice_id # AI voice ID for interviewer
      questions_table.integer :order_index             # Question sequence order

      questions_table.timestamps
    end
  end
end

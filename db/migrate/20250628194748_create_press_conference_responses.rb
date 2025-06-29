# Creates the press conference responses table for AI-generated player responses.
# 
# This table stores AI-generated responses to press conference questions, delivered
# in each league member's actual voice using their voice clone. Key design decisions:
# 
# - press_conference_question: Each response answers a specific question
# - response_text: AI-generated text response based on team performance and context
# - response_audio_url: Audio version using the target manager's voice clone
# - generation_prompt: The prompt used to generate the response (for debugging/tuning)
# 
# This completes the press conference experience: AI generates contextual responses
# about the player's team performance and delivers them using their actual voice,
# creating highly personalized and engaging fantasy football content.
class CreatePressConferenceResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :press_conference_responses do |responses_table|
      responses_table.references :press_conference_question, null: false, foreign_key: true
      responses_table.text :response_text         # AI-generated response text
      responses_table.string :response_audio_url  # Audio using member's voice clone
      responses_table.text :generation_prompt     # Prompt used for AI generation

      responses_table.timestamps
    end
  end
end

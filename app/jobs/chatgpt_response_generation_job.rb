# Background job to generate ChatGPT responses for press conference questions.
# This job processes all questions for a press conference and creates response records.
class ChatgptResponseGenerationJob < ApplicationJob
  queue_as :default

  # Hardcoded league context for Phase 1
  LEAGUE_CONTEXT = {
    nature: "Fantasy football league with 12 competitive friends",
    tone: "Humorous but competitive, with light trash talk",
    rivalries: "Focus on season-long rivalries and recent matchups",
    history: "League has been running for 5+ years with established personalities",
    response_style: "Confident, slightly cocky, but good-natured",
  }.freeze

  def perform(press_conference_id)
    press_conference = PressConference.find(press_conference_id)
    original_status = press_conference.status

    Rails.logger.info "Starting ChatGPT response generation for press conference #{press_conference_id}"

    begin
      chatgpt_client = ChatgptClient.new

      # Update status to generating only after successful initialization
      press_conference.update!(status: :generating)

      # Process each question in order
      press_conference.press_conference_questions.order(:order_index).each do |question|
        Rails.logger.info "Generating response for question #{question.id}: #{question.question_text}"

        # Generate response using ChatGPT
        response_text = chatgpt_client.generate_response(question.question_text, LEAGUE_CONTEXT)

        # Create the response record
        question.create_press_conference_response!(
          response_text: response_text,
          generation_prompt: build_generation_prompt(question.question_text, LEAGUE_CONTEXT)
        )

        Rails.logger.info "Generated response for question #{question.id}"
      end

      # Update status to ready after all responses are generated
      press_conference.update!(status: :ready)

      Rails.logger.info "Completed ChatGPT response generation for press conference #{press_conference_id}"
    rescue StandardError => e
      # Revert status on failure
      press_conference.update!(status: original_status)
      Rails.logger.error "Failed to generate ChatGPT responses for press conference #{press_conference_id}: #{e.message}"
      # Re-raise the error to let the job queue handle retries
      raise e
    end
  end

  private

  def build_generation_prompt(question, league_context)
    "Question: #{question}\nLeague Context: #{league_context.values.join(', ')}"
  end
end

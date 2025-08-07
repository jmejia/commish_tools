# Background job to generate ChatGPT responses for press conference questions.
# This job processes all questions for a press conference and creates response records.
class ChatgptResponseGenerationJob < ApplicationJob
  queue_as :default

  def perform(press_conference_id)
    press_conference = PressConference.find(press_conference_id)
    original_status = press_conference.status

    Rails.logger.info "Starting ChatGPT response generation for press conference #{press_conference_id}"

    begin
      chatgpt_client = ChatgptClient.new
      league_context = get_league_context(press_conference)

      # Update status to generating only after successful initialization
      press_conference.update!(status: :generating)

      # Process each question in order
      press_conference.press_conference_questions.order(:order_index).each do |question|
        Rails.logger.info "Generating response for question #{question.id}: #{question.question_text}"

        # Generate response using ChatGPT
        response_text = chatgpt_client.generate_response(question.question_text, league_context)

        # Create the response record
        response = question.create_press_conference_response!(
          response_text: response_text,
          generation_prompt: build_generation_prompt(question.question_text, league_context)
        )

        Rails.logger.info "Generated response for question #{question.id}"

        # Enqueue audio generation jobs
        QuestionAudioGenerationJob.perform_later(question.id)
        ResponseAudioGenerationJob.perform_later(response.id)
      end

      # Update status to ready after all responses are generated
      press_conference.update!(status: :ready)

      Rails.logger.info "Completed ChatGPT response generation for press conference #{press_conference_id}"
    rescue StandardError => e
      # Revert status on failure
      press_conference.update!(status: original_status)
      msg = "Failed to generate ChatGPT responses for press conference #{press_conference_id}: #{e.message}"
      Rails.logger.error msg
      # Re-raise the error to let the job queue handle retries
      raise e
    end
  end

  private

  def get_league_context(press_conference)
    league_context = press_conference.league.league_context

    if league_context&.has_content?
      league_context.structured_content
    else
      # Default fallback context
      {
        nature: "Fantasy football league with competitive players",
        tone: "Humorous but competitive, with light trash talk",
        rivalries: "Focus on season-long rivalries and recent matchups",
        history: "League has been running with established personalities",
        response_style: "Confident, slightly cocky, but good-natured",
      }
    end
  end

  def build_generation_prompt(question, league_context)
    context_summary = league_context.values.compact_blank.join(', ')
    "Question: #{question}\nLeague Context: #{context_summary}"
  end
end

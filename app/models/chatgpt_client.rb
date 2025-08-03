# Client for interacting with OpenAI's ChatGPT API to generate fantasy football
# press conference responses based on league context and questions.
class ChatgptClient
  class GenerationError < StandardError; end

  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    raise ArgumentError, "OpenAI API key not configured" if @api_key.blank?
  end

  def generate_response(question, league_context)
    prompt = build_prompt(question, league_context)

    response = openai_client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 200,
        temperature: 0.8,
      }
    )

    extract_response_text(response)
  rescue StandardError => e
    Rails.logger.error "ChatGPT API error: #{e.message}"
    raise GenerationError, "Failed to generate response: #{e.message}"
  end

  private

  def openai_client
    @openai_client ||= OpenAI::Client.new(access_token: @api_key)
  end

  def build_prompt(question, league_context)
    <<~PROMPT
      You are a fantasy football player in a press conference. Generate a response to the following question based on the league context provided.

      League Context:
      - Nature: #{league_context[:nature]}
      - Tone: #{league_context[:tone]}
      - Rivalries: #{league_context[:rivalries]}
      - History: #{league_context[:history]}
      - Response Style: #{league_context[:response_style]}

      Question: #{question}

      Generate a response that fits the league's tone and style. Keep it under 150 words, engaging, and in character for a fantasy football player who is confident about their team.
    PROMPT
  end

  def extract_response_text(response)
    choices = response.dig("choices")

    if choices.blank?
      raise GenerationError, "No response generated from OpenAI API"
    end

    content = choices.first.dig("message", "content")

    if content.blank?
      raise GenerationError, "Empty response from OpenAI API"
    end

    content.strip
  end
end

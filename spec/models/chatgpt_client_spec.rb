require 'rails_helper'

RSpec.describe ChatgptClient do
  let(:client) { described_class.new }
  let(:question) { "How do you feel about your team's performance this week?" }
  let(:league_context) do
    {
      nature: "Fantasy football league with 12 competitive friends",
      tone: "Humorous but competitive, with light trash talk",
      rivalries: "Focus on season-long rivalries and recent matchups",
      history: "League has been running for 5+ years with established personalities",
      response_style: "Confident, slightly cocky, but good-natured",
    }
  end

  describe '#generate_response' do
    context 'when OpenAI API returns a successful response' do
      it 'generates a response based on the question and league context' do
        # Mock the OpenAI API call
        openai_response = {
          "choices" => [
            {
              "message" => {
                "content" => "Listen, my team's performance this week? Absolutely dominant! While you scrubs were struggling to get double digits, I was out here putting up numbers that would make Tom Brady jealous. My roster is stacked, my strategy is flawless, and my opponents? Well, let's just say they're learning what it means to face a fantasy football legend. This week was just a preview of the championship run I'm about to unleash on this league!",
              },
            },
          ],
        }

        mock_client = double('OpenAI::Client')
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_return(openai_response)

        result = client.generate_response(question, league_context)

        expect(result).to be_a(String)
        expect(result).to include("my team's performance")
        expect(result.length).to be > 50 # Ensure we get a substantial response
      end
    end

    context 'when OpenAI API returns an error' do
      it 'raises an error with descriptive message' do
        mock_client = double('OpenAI::Client')
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_raise(StandardError.new("API Error"))

        expect do
          client.generate_response(question, league_context)
        end.to raise_error(ChatgptClient::GenerationError, /Failed to generate response/)
      end
    end

    context 'when OpenAI API returns unexpected format' do
      it 'handles missing choices gracefully' do
        openai_response = { "choices" => [] }

        mock_client = double('OpenAI::Client')
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_return(openai_response)

        expect do
          client.generate_response(question, league_context)
        end.to raise_error(ChatgptClient::GenerationError, /No response generated/)
      end
    end
  end

  describe '#build_prompt' do
    it 'constructs a prompt with league context and question' do
      prompt = client.send(:build_prompt, question, league_context)

      expect(prompt).to include("Fantasy football league")
      expect(prompt).to include("Humorous but competitive")
      expect(prompt).to include("Confident, slightly cocky")
      expect(prompt).to include(question)
    end
  end
end

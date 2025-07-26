require 'rails_helper'

RSpec.describe ChatgptResponseGenerationJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:league) { create(:league, owner: user) }
  let(:target_member) { create(:league_membership, league: league, user: create(:user)) }
  let(:press_conference) do
    create(:press_conference, league: league, target_manager: target_member, status: :draft)
  end
  let!(:question_1) do
    create(:press_conference_question, 
           press_conference: press_conference, 
           question_text: "How do you feel about your team?",
           order_index: 1)
  end
  let!(:question_2) do
    create(:press_conference_question, 
           press_conference: press_conference, 
           question_text: "What's your strategy?",
           order_index: 2)
  end
  let!(:question_3) do
    create(:press_conference_question, 
           press_conference: press_conference, 
           question_text: "Any predictions?",
           order_index: 3)
  end

  before do
    # Mock ChatGPT client to avoid real API calls
    allow_any_instance_of(ChatgptClient).to receive(:generate_response).and_return(
      "This is a mocked AI response that sounds confident and engaging."
    )
  end

  describe '#perform' do
    it 'generates responses for all press conference questions' do
      expect do
        described_class.perform_now(press_conference.id)
      end.to change { press_conference.press_conference_responses.count }.from(0).to(3)
    end

    it 'creates responses in the correct order' do
      described_class.perform_now(press_conference.id)
      
      responses = press_conference.press_conference_responses.joins(:press_conference_question)
                                 .order('press_conference_questions.order_index')
      
      expect(responses.count).to eq(3)
      expect(responses.first.press_conference_question).to eq(question_1)
      expect(responses.second.press_conference_question).to eq(question_2)
      expect(responses.third.press_conference_question).to eq(question_3)
    end

    it 'stores the generated response text' do
      described_class.perform_now(press_conference.id)
      
      responses = press_conference.press_conference_responses
      expect(responses.all? { |r| r.response_text.present? }).to be true
      expect(responses.first.response_text).to include("mocked AI response")
    end

    it 'uses default league context when none available' do
      chatgpt_client = double('ChatgptClient')
      allow(ChatgptClient).to receive(:new).and_return(chatgpt_client)
      
      default_context = {
        nature: "Fantasy football league with competitive players",
        tone: "Humorous but competitive, with light trash talk",
        rivalries: "Focus on season-long rivalries and recent matchups",
        history: "League has been running with established personalities",
        response_style: "Confident, slightly cocky, but good-natured"
      }
      
      expect(chatgpt_client).to receive(:generate_response)
        .with("How do you feel about your team?", default_context)
        .and_return("Response 1")
      expect(chatgpt_client).to receive(:generate_response)
        .with("What's your strategy?", default_context)
        .and_return("Response 2")  
      expect(chatgpt_client).to receive(:generate_response)
        .with("Any predictions?", default_context)
        .and_return("Response 3")
      
      described_class.perform_now(press_conference.id)
    end

    it 'uses custom league context when available' do
      league_context = create(:league_context, league: league)
      league_context.nature = "College friends league"
      league_context.tone = "Friendly but competitive"
      league_context.rivalries = "John vs Mike rivalry"
      league_context.history = "5 year running league"
      league_context.response_style = "Confident and witty"
      league_context.save!
      
      chatgpt_client = double('ChatgptClient')
      allow(ChatgptClient).to receive(:new).and_return(chatgpt_client)
      
      expected_context = {
        nature: "College friends league",
        tone: "Friendly but competitive", 
        rivalries: "John vs Mike rivalry",
        history: "5 year running league",
        response_style: "Confident and witty"
      }
      
      expect(chatgpt_client).to receive(:generate_response)
        .with("How do you feel about your team?", expected_context)
        .and_return("Response 1")
      expect(chatgpt_client).to receive(:generate_response)
        .with("What's your strategy?", expected_context)
        .and_return("Response 2")  
      expect(chatgpt_client).to receive(:generate_response)
        .with("Any predictions?", expected_context)
        .and_return("Response 3")
      
      described_class.perform_now(press_conference.id)
    end

    it 'updates press conference status to ready after completion' do
      expect do
        described_class.perform_now(press_conference.id)
      end.to change { press_conference.reload.status }.from('draft').to('ready')
    end

    context 'when ChatGPT API fails' do
      before do
        allow_any_instance_of(ChatgptClient).to receive(:generate_response)
          .and_raise(ChatgptClient::GenerationError, "API Error")
      end

      it 'does not create any responses' do
        expect do
          described_class.perform_now(press_conference.id)
        rescue ChatgptClient::GenerationError
          # Expected to raise
        end.not_to change { press_conference.press_conference_responses.count }
      end

      it 'does not change press conference status' do
        expect do
          described_class.perform_now(press_conference.id)
        rescue ChatgptClient::GenerationError
          # Expected to raise
        end.not_to change { press_conference.reload.status }
      end
    end

    context 'when press conference does not exist' do
      it 'raises an error' do
        expect do
          described_class.perform_now(999999)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end 
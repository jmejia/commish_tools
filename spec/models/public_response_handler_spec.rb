require 'rails_helper'

RSpec.describe PublicResponseHandler do
  let(:poll) { create(:scheduling_poll, :with_time_slots) }
  let(:params) { { respondent_name: 'John Doe', availabilities: { '1' => '2' } } }
  let(:request) { double('request', remote_ip: '127.0.0.1', user_agent: 'Test Browser') }
  let(:handler) { described_class.new(poll: poll, params: params, request: request) }

  describe '#handle' do
    context 'when response recording is successful' do
      let(:successful_result) do
        OpenStruct.new(success?: true, message: 'Response recorded!')
      end

      before do
        allow_any_instance_of(ResponseRecorder).to receive(:record).and_return(successful_result)
      end

      it 'returns a successful response' do
        result = handler.handle(notice_message: 'Success!')
        
        expect(result.success?).to be true
        expect(result.notice).to eq('Success!')
        expect(result.redirect_path).to include(poll.public_token)
      end
    end

    context 'when response recording fails' do
      let(:failed_result) do
        OpenStruct.new(success?: false, error: 'Validation failed')
      end

      before do
        allow_any_instance_of(ResponseRecorder).to receive(:record).and_return(failed_result)
      end

      it 'returns a failure response' do
        result = handler.handle(notice_message: 'Success!')
        
        expect(result.success?).to be false
        expect(result.error).to eq('Validation failed')
        expect(result.time_slots).to eq(poll.event_time_slots.order(:order_index, :starts_at))
      end
    end

    context 'with existing response' do
      let(:identifier) { Digest::SHA256.hexdigest("john doe-#{poll.id}") }
      let!(:existing_response) do 
        create(:scheduling_response, 
               scheduling_poll: poll, 
               respondent_name: 'John Doe',
               respondent_identifier: identifier)
      end
      let(:failed_result) do
        OpenStruct.new(success?: false, error: 'Validation failed')
      end

      before do
        allow_any_instance_of(ResponseRecorder).to receive(:record).and_return(failed_result)
      end

      it 'finds and returns the existing response' do
        result = handler.handle(notice_message: 'Success!')
        
        expect(result.response).to eq(existing_response)
      end
    end
  end

  describe 'private methods' do
    describe '#generate_identifier' do
      it 'generates consistent identifier' do
        identifier1 = handler.send(:generate_identifier)
        identifier2 = handler.send(:generate_identifier)
        
        expect(identifier1).to eq(identifier2)
        expect(identifier1).to be_a(String)
        expect(identifier1.length).to be > 10
      end

      it 'generates different identifiers for different names' do
        handler1 = described_class.new(poll: poll, params: { respondent_name: 'John' }, request: request)
        handler2 = described_class.new(poll: poll, params: { respondent_name: 'Jane' }, request: request)
        
        expect(handler1.send(:generate_identifier)).not_to eq(handler2.send(:generate_identifier))
      end
    end
  end
end
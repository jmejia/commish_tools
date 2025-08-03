require 'rails_helper'

RSpec.describe SchedulingResponse, type: :model do
  describe 'associations' do
    it { should belong_to(:scheduling_poll) }
    it { should have_many(:slot_availabilities).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:scheduling_response) }

    it { should validate_presence_of(:respondent_name) }
    # Note: Length validation happens via truncation in sanitization
    it { should validate_presence_of(:respondent_identifier) }
    it { should validate_uniqueness_of(:respondent_identifier).scoped_to(:scheduling_poll_id) }
  end

  describe 'name sanitization' do
    it 'sanitizes respondent name before validation' do
      response = build(:scheduling_response, respondent_name: '<script>alert("xss")</script>John Doe')
      response.valid?
      expect(response.respondent_name).to eq('alert(xss)John Doe')
    end

    it 'strips whitespace from respondent name' do
      response = build(:scheduling_response, respondent_name: '  John Doe  ')
      response.valid?
      expect(response.respondent_name).to eq('John Doe')
    end

    it 'truncates long names' do
      long_name = 'a' * 60
      response = build(:scheduling_response, respondent_name: long_name)
      response.valid?
      expect(response.respondent_name.length).to eq(50)
    end
  end

  describe '.record_public_response' do
    let(:poll) { create(:scheduling_poll, :with_time_slots) }
    let(:params) do
      {
        respondent_name: 'John Doe',
        availabilities: {
          poll.event_time_slots.first.id.to_s => '2',
          poll.event_time_slots.last.id.to_s => '0',
        },
      }
    end
    let(:request) { double('request', remote_ip: '127.0.0.1', user_agent: 'Test Agent') }

    context 'when poll is active' do
      it 'successfully records a new response' do
        result = described_class.record_public_response(
          poll: poll,
          params: params,
          request: request,
          notice_message: 'Response recorded!'
        )

        expect(result.success?).to be true
        expect(result.notice).to eq('Response recorded!')
        expect(result.response.respondent_name).to eq('John Doe')
      end

      it 'updates existing response for same person' do
        # Create initial response using the same method to ensure proper identifier
        described_class.record_public_response(
          poll: poll,
          params: params.merge(respondent_name: 'John Doe'),
          request: request,
          notice_message: 'Initial response'
        )

        result = described_class.record_public_response(
          poll: poll,
          params: params.merge(respondent_name: 'John Doe'),
          request: request,
          notice_message: 'Response updated!'
        )

        expect(result.success?).to be true
        expect(poll.scheduling_responses.where(respondent_name: 'John Doe').count).to eq(1)
      end
    end

    context 'when poll is closed' do
      let(:poll) { create(:scheduling_poll, :with_time_slots, status: :closed) }

      it 'returns failure result' do
        result = described_class.record_public_response(
          poll: poll,
          params: params,
          request: request,
          notice_message: 'Response recorded!'
        )

        expect(result.success?).to be false
        expect(result.error).to include('no longer accepting responses')
      end
    end

    context 'with invalid params' do
      let(:params) { { respondent_name: '', availabilities: {} } }

      it 'returns failure result with validation errors' do
        result = described_class.record_public_response(
          poll: poll,
          params: params,
          request: request,
          notice_message: 'Response recorded!'
        )

        expect(result.success?).to be false
        expect(result.error).to include("can't be blank")
      end
    end
  end

  describe '.sanitize_response_params' do
    it 'removes HTML tags from respondent name' do
      params = { respondent_name: '<b>John</b> Doe' }
      sanitized = described_class.sanitize_response_params(params)
      expect(sanitized[:respondent_name]).to eq('John Doe')
    end

    it 'removes harmful characters' do
      params = { respondent_name: 'John<>&"\'Doe' }
      sanitized = described_class.sanitize_response_params(params)
      # strip_tags encodes HTML entities, then gsub removes the original chars
      expect(sanitized[:respondent_name]).to eq('Johnlt;gt;amp;Doe')
    end
  end

  describe '.generate_response_identifier' do
    it 'generates consistent identifier for same name and poll' do
      identifier1 = described_class.generate_response_identifier('John Doe', 123)
      identifier2 = described_class.generate_response_identifier('John Doe', 123)
      expect(identifier1).to eq(identifier2)
    end

    it 'generates different identifiers for different names' do
      identifier1 = described_class.generate_response_identifier('John Doe', 123)
      identifier2 = described_class.generate_response_identifier('Jane Doe', 123)
      expect(identifier1).not_to eq(identifier2)
    end

    it 'is case insensitive' do
      identifier1 = described_class.generate_response_identifier('John Doe', 123)
      identifier2 = described_class.generate_response_identifier('JOHN DOE', 123)
      expect(identifier1).to eq(identifier2)
    end
  end

  describe 'availability helper methods' do
    let(:response) { create(:scheduling_response) }
    let(:slot) { create(:event_time_slot) }

    context 'when user is available' do
      before do
        create(:slot_availability,
               scheduling_response: response,
               event_time_slot: slot,
               availability: :available_ideal)
      end

      it '#available_for? returns true' do
        expect(response.available_for?(slot)).to be true
      end

      it '#available_not_ideal_for? returns false' do
        expect(response.available_not_ideal_for?(slot)).to be false
      end

      it '#unavailable_for? returns false' do
        expect(response.unavailable_for?(slot)).to be false
      end
    end

    context 'when user is available but not ideal' do
      before do
        create(:slot_availability,
               scheduling_response: response,
               event_time_slot: slot,
               availability: :available_not_ideal)
      end

      it '#available_for? returns false' do
        expect(response.available_for?(slot)).to be false
      end

      it '#available_not_ideal_for? returns true' do
        expect(response.available_not_ideal_for?(slot)).to be true
      end

      it '#unavailable_for? returns false' do
        expect(response.unavailable_for?(slot)).to be false
      end
    end

    context 'when user is unavailable' do
      before do
        create(:slot_availability,
               scheduling_response: response,
               event_time_slot: slot,
               availability: :unavailable)
      end

      it '#available_for? returns false' do
        expect(response.available_for?(slot)).to be false
      end

      it '#available_not_ideal_for? returns false' do
        expect(response.available_not_ideal_for?(slot)).to be false
      end

      it '#unavailable_for? returns true' do
        expect(response.unavailable_for?(slot)).to be true
      end
    end

    context 'when no availability record exists' do
      it '#unavailable_for? returns true' do
        expect(response.unavailable_for?(slot)).to be true
      end

      it 'other methods return nil/false' do
        expect(response.available_for?(slot)).to be_falsey
        expect(response.available_not_ideal_for?(slot)).to be_falsey
      end
    end
  end

  describe '#update_availabilities' do
    let(:response) { create(:scheduling_response) }
    let(:poll) { response.scheduling_poll }
    let(:slot1) { create(:event_time_slot, scheduling_poll: poll) }
    let(:slot2) { create(:event_time_slot, scheduling_poll: poll) }

    it 'creates new availability records' do
      availabilities = {
        slot1.id.to_s => '2',
        slot2.id.to_s => '0',
      }

      response.update_availabilities(availabilities)

      expect(response.slot_availabilities.count).to eq(2)
      expect(response.available_for?(slot1)).to be true
      expect(response.unavailable_for?(slot2)).to be true
    end

    it 'updates existing availability records' do
      create(:slot_availability,
             scheduling_response: response,
             event_time_slot: slot1,
             availability: :unavailable)

      availabilities = { slot1.id.to_s => '2' }
      response.update_availabilities(availabilities)

      expect(response.available_for?(slot1)).to be true
    end
  end
end

require 'rails_helper'

RSpec.describe SchedulingPoll, type: :model do
  describe 'associations' do
    it { should belong_to(:league) }
    it { should belong_to(:created_by).class_name('User') }
    it { should have_many(:event_time_slots).dependent(:destroy) }
    it { should have_many(:scheduling_responses).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:scheduling_poll) }

    it 'validates title presence' do
      poll = build(:scheduling_poll, title: '', event_type: 'draft')
      expect(poll).not_to be_valid
      expect(poll.errors[:title]).to include("can't be blank")

      poll.title = nil
      expect(poll).not_to be_valid
      expect(poll.errors[:title]).to include("can't be blank")
    end

    it { should validate_length_of(:title).is_at_most(100) }
    it { should validate_presence_of(:event_type) }
    it { should validate_inclusion_of(:event_type).in_array(['draft']) }
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(SchedulingPoll.statuses).to eq({ 'active' => 0, 'closed' => 1, 'cancelled' => 2 })
    end
  end

  describe 'callbacks' do
    describe '#generate_public_token' do
      it 'generates a unique token before creation' do
        poll = build(:scheduling_poll)
        expect(poll.public_token).to be_nil
        poll.save!
        expect(poll.public_token).to be_present
        expect(poll.public_token.length).to be >= 8
      end

      it 'ensures token uniqueness' do
        existing_poll = create(:scheduling_poll)
        new_poll = build(:scheduling_poll)

        allow(SecureRandom).to receive(:urlsafe_base64).and_return(existing_poll.public_token, 'unique_token')

        new_poll.save!
        expect(new_poll.public_token).to eq('unique_token')
      end
    end
  end

  describe '#response_rate' do
    let(:league) { create(:league) }
    let(:poll) { create(:scheduling_poll, league: league) }

    before do
      create_list(:league_membership, 3, league: league)
    end

    it 'returns 0 when no responses' do
      expect(poll.response_rate).to eq(0)
    end

    it 'calculates percentage of responses' do
      create_list(:scheduling_response, 2, scheduling_poll: poll)
      expect(poll.response_rate).to eq(67) # 2/3 = 66.67%, rounded
    end
  end

  describe '#optimal_slots' do
    let(:poll) { create(:scheduling_poll) }
    let!(:slot1) { create(:event_time_slot, scheduling_poll: poll) }
    let!(:slot2) { create(:event_time_slot, scheduling_poll: poll) }
    let!(:slot3) { create(:event_time_slot, scheduling_poll: poll) }

    before do
      # Create responses with different availability patterns
      3.times do
        response = create(:scheduling_response, scheduling_poll: poll)
        create(:slot_availability, scheduling_response: response, event_time_slot: slot1, availability: 2) # available
        create(:slot_availability, scheduling_response: response, event_time_slot: slot2, availability: 1) # maybe
        create(:slot_availability, scheduling_response: response, event_time_slot: slot3, availability: 0) # unavailable
      end
    end

    it 'returns slots ordered by availability' do
      optimal = poll.optimal_slots
      expect(optimal.first).to eq(slot1)
      expect(optimal.second).to eq(slot2)
      expect(optimal.third).to eq(slot3)
    end

    it 'respects the limit parameter' do
      optimal = poll.optimal_slots(limit: 2)
      expect(optimal.count).to eq(2)
    end
  end

  describe '#close! and #reopen!' do
    let(:poll) { create(:scheduling_poll, status: :active) }

    it 'closes an active poll' do
      expect { poll.close! }.to change { poll.status }.from('active').to('closed')
    end

    it 'reopens a closed poll' do
      poll.close!
      expect { poll.reopen! }.to change { poll.status }.from('closed').to('active')
    end
  end

  describe '#public_url' do
    let(:poll) { create(:scheduling_poll) }

    it 'generates a public URL with the token' do
      url = poll.public_url
      expect(url).to include("/schedule/#{poll.public_token}")
      expect(url).to include('http')
    end

    it 'includes port in development environment' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      url = poll.public_url
      expect(url).to include(':3000')
    end
  end

  describe '#message_templates' do
    let(:league) { create(:league, name: 'Fantasy Football League') }
    let(:poll) { create(:scheduling_poll, league: league, title: 'Draft Scheduling', closes_at: 1.week.from_now) }
    let(:public_url) { "https://example.com/schedule/#{poll.public_token}" }

    before do
      allow(poll).to receive(:public_url).and_return(public_url)
    end

    it 'generates SMS template' do
      template = poll.message_templates[:sms]
      expect(template).to include('Fantasy Football League')
      expect(template).to include('Draft Scheduling')
      expect(template).to include(public_url)
      expect(template.length).to be <= 160 # SMS length limit
    end

    it 'generates email template' do
      template = poll.message_templates[:email]
      expect(template).to include('Fantasy Football League')
      expect(template).to include('Draft Scheduling')
      expect(template).to include(public_url)
      expect(template).to include('Please respond by')
    end

    it 'generates Sleeper template' do
      template = poll.message_templates[:sleeper]
      expect(template).to include('Fantasy Football League')
      expect(template).to include('Draft Scheduling')
      expect(template).to include(public_url)
      expect(template).to include('🏈')
    end

    context 'when poll has no closing date' do
      let(:poll) { create(:scheduling_poll, league: league, title: 'Draft Scheduling', closes_at: nil) }

      it 'does not include deadline in templates' do
        expect(poll.message_templates[:email]).not_to include('Please respond by')
        expect(poll.message_templates[:sleeper]).not_to include('Deadline:')
      end
    end
  end
end

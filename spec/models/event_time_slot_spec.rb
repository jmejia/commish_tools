require 'rails_helper'

RSpec.describe EventTimeSlot, type: :model do
  describe 'associations' do
    it { should belong_to(:scheduling_poll) }
    it { should have_many(:slot_availabilities).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:starts_at) }
    it { should validate_presence_of(:duration_minutes) }
    it { should validate_numericality_of(:duration_minutes).is_greater_than(0) }
  end

  describe 'delegations' do
    it 'delegates event_type to scheduling_poll' do
      poll = create(:scheduling_poll, event_type: 'draft')
      slot = create(:event_time_slot, scheduling_poll: poll)
      expect(slot.event_type).to eq('draft')
    end
  end

  describe '#ends_at' do
    it 'calculates end time based on start time and duration' do
      start_time = Time.zone.parse('2024-08-15 19:00:00')
      slot = build(:event_time_slot, starts_at: start_time, duration_minutes: 180)

      expected_end = start_time + 180.minutes
      expect(slot.ends_at).to eq(expected_end)
    end
  end

  describe '#availability_summary' do
    let(:slot) { create(:event_time_slot) }

    context 'with no responses' do
      it 'returns zeros for all availability types' do
        summary = slot.availability_summary
        expect(summary).to eq({
          available: 0,
          maybe: 0,
          unavailable: 0,
        })
      end
    end

    context 'with responses' do
      before do
        poll = slot.scheduling_poll

        3.times do |i|
          response = create(:scheduling_response,
                          scheduling_poll: poll,
                          respondent_name: "Available User #{i + 1}",
                          respondent_identifier: "available_#{i + 1}")
          create(:slot_availability,
                 scheduling_response: response,
                 event_time_slot: slot,
                 availability: :available)
        end

        2.times do |i|
          response = create(:scheduling_response,
                          scheduling_poll: poll,
                          respondent_name: "Maybe User #{i + 1}",
                          respondent_identifier: "maybe_#{i + 1}")
          create(:slot_availability,
                 scheduling_response: response,
                 event_time_slot: slot,
                 availability: :maybe)
        end

        response = create(:scheduling_response,
                        scheduling_poll: poll,
                        respondent_name: "Unavailable User",
                        respondent_identifier: "unavailable_1")
        create(:slot_availability,
               scheduling_response: response,
               event_time_slot: slot,
               availability: :unavailable)
      end

      it 'counts each availability type correctly' do
        summary = slot.availability_summary
        expect(summary).to eq({
          available: 3,
          maybe: 2,
          unavailable: 1,
        })
      end
    end
  end

  describe '#available_count' do
    let(:slot) { create(:event_time_slot) }

    it 'returns the count of available responses' do
      poll = slot.scheduling_poll

      2.times do |i|
        response = create(:scheduling_response,
                        scheduling_poll: poll,
                        respondent_name: "Available User #{i + 1}",
                        respondent_identifier: "available_count_#{i + 1}")
        create(:slot_availability,
               scheduling_response: response,
               event_time_slot: slot,
               availability: :available)
      end

      expect(slot.available_count).to eq(2)
    end
  end

  describe '#availability_score' do
    let(:slot) { create(:event_time_slot) }

    context 'with no responses' do
      it 'returns 0' do
        expect(slot.availability_score).to eq(0)
      end
    end

    context 'with mixed responses' do
      before do
        # 2 available (2 points each), 1 maybe (1 point), 1 unavailable (0 points)
        # Total: 5 points out of 8 possible (4 responses * 2 max points)
        # Score: 5/8 * 100 = 62.5%, rounded to 63%
        poll = slot.scheduling_poll

        2.times do |i|
          response = create(:scheduling_response,
                          scheduling_poll: poll,
                          respondent_name: "Available Score #{i + 1}",
                          respondent_identifier: "available_score_#{i + 1}")
          create(:slot_availability,
                 scheduling_response: response,
                 event_time_slot: slot,
                 availability: :available)
        end

        response = create(:scheduling_response,
                        scheduling_poll: poll,
                        respondent_name: "Maybe Score",
                        respondent_identifier: "maybe_score_1")
        create(:slot_availability,
               scheduling_response: response,
               event_time_slot: slot,
               availability: :maybe)

        response = create(:scheduling_response,
                        scheduling_poll: poll,
                        respondent_name: "Unavailable Score",
                        respondent_identifier: "unavailable_score_1")
        create(:slot_availability,
               scheduling_response: response,
               event_time_slot: slot,
               availability: :unavailable)
      end

      it 'calculates weighted score correctly' do
        expect(slot.availability_score).to eq(63) # 5/8 * 100 = 62.5, rounded to 63
      end
    end

    context 'with all available responses' do
      before do
        poll = slot.scheduling_poll

        3.times do |i|
          response = create(:scheduling_response,
                          scheduling_poll: poll,
                          respondent_name: "All Available #{i + 1}",
                          respondent_identifier: "all_available_#{i + 1}")
          create(:slot_availability,
                 scheduling_response: response,
                 event_time_slot: slot,
                 availability: :available)
        end
      end

      it 'returns 100' do
        expect(slot.availability_score).to eq(100)
      end
    end
  end

  describe '#formatted_time' do
    it 'formats the start time in a readable format' do
      start_time = Time.zone.parse('2024-08-15 19:00:00')
      slot = build(:event_time_slot, starts_at: start_time)

      expected_format = 'August 15, 2024 at  7:00 PM'
      expect(slot.formatted_time).to eq(expected_format)
    end

    it 'handles different times correctly' do
      start_time = Time.zone.parse('2024-12-25 09:30:00')
      slot = build(:event_time_slot, starts_at: start_time)

      expected_format = 'December 25, 2024 at  9:30 AM'
      expect(slot.formatted_time).to eq(expected_format)
    end
  end

  describe '#display_label' do
    context 'for draft events' do
      let(:poll) { create(:scheduling_poll, event_type: 'draft') }
      let(:slot) do
        create(:event_time_slot,
                         scheduling_poll: poll,
                         starts_at: Time.zone.parse('2024-08-15 19:00:00'),
                         duration_minutes: 180)
      end

      it 'shows draft-specific format with hour duration' do
        expected = 'August 15, 2024 at  7:00 PM - 3hr draft window'
        expect(slot.display_label).to eq(expected)
      end
    end

    context 'for other event types' do
      let(:poll) { create(:scheduling_poll, event_type: 'meeting') }
      let(:slot) do
        create(:event_time_slot,
                         scheduling_poll: poll,
                         starts_at: Time.zone.parse('2024-08-15 19:00:00'),
                         duration_minutes: 60)
      end

      it 'shows generic format with minute duration' do
        expected = 'August 15, 2024 at  7:00 PM - 60min'
        expect(slot.display_label).to eq(expected)
      end
    end
  end
end

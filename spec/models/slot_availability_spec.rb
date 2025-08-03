require 'rails_helper'

RSpec.describe SlotAvailability, type: :model do
  describe 'associations' do
    it { should belong_to(:scheduling_response) }
    it { should belong_to(:event_time_slot) }
  end

  describe 'validations' do
    it { should validate_presence_of(:availability) }
  end

  describe 'enums' do
    it 'defines availability enum correctly' do
      expect(SlotAvailability.availabilities).to eq({
        'unavailable' => 0,
        'available_not_ideal' => 1,
        'available_ideal' => 2,
      })
    end

    it 'allows setting availability by name' do
      availability = build(:slot_availability, availability: :available_ideal)
      expect(availability.availability).to eq('available_ideal')
      expect(availability.available_ideal?).to be true
    end

    it 'allows setting availability by number' do
      availability = build(:slot_availability, availability: 1)
      expect(availability.availability).to eq('available_not_ideal')
      expect(availability.available_not_ideal?).to be true
    end
  end

  describe 'availability states' do
    let(:availability) { build(:slot_availability) }

    it 'responds to availability state queries' do
      availability.availability = :unavailable
      expect(availability.unavailable?).to be true
      expect(availability.available_not_ideal?).to be false
      expect(availability.available_ideal?).to be false

      availability.availability = :available_not_ideal
      expect(availability.unavailable?).to be false
      expect(availability.available_not_ideal?).to be true
      expect(availability.available_ideal?).to be false

      availability.availability = :available_ideal
      expect(availability.unavailable?).to be false
      expect(availability.available_not_ideal?).to be false
      expect(availability.available_ideal?).to be true
    end
  end

  describe 'factory' do
    it 'creates a valid slot availability' do
      availability = create(:slot_availability)
      expect(availability).to be_valid
      expect(availability.scheduling_response).to be_present
      expect(availability.event_time_slot).to be_present
      expect(availability.availability).to be_present
    end
  end

  describe 'database constraints' do
    it 'enforces uniqueness of response and slot combination' do
      response = create(:scheduling_response)
      slot = create(:event_time_slot)

      create(:slot_availability,
             scheduling_response: response,
             event_time_slot: slot,
             availability: :available_ideal)

      duplicate = build(:slot_availability,
                       scheduling_response: response,
                       event_time_slot: slot,
                       availability: :available_not_ideal)

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end

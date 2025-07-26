class CreateSlotAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :slot_availabilities do |t|
      t.bigint :scheduling_response_id, null: false
      t.bigint :event_time_slot_id, null: false
      t.integer :availability, null: false
      t.jsonb :preference_data, default: {}

      t.timestamps
    end

    add_index :slot_availabilities, [:scheduling_response_id, :event_time_slot_id],
              name: 'index_slot_availability_unique', unique: true
    add_index :slot_availabilities, :event_time_slot_id

    add_foreign_key :slot_availabilities, :scheduling_responses
    add_foreign_key :slot_availabilities, :event_time_slots
  end
end

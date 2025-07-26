class CreateEventTimeSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :event_time_slots do |t|
      t.bigint :scheduling_poll_id, null: false
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, default: 60, null: false
      t.jsonb :slot_metadata, default: {}
      t.integer :order_index, default: 0

      t.timestamps
    end

    add_index :event_time_slots, :scheduling_poll_id
    add_index :event_time_slots, :starts_at

    add_foreign_key :event_time_slots, :scheduling_polls
  end
end

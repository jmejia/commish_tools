class AddPerformanceIndexesToScheduling < ActiveRecord::Migration[8.0]
  def change
    # Composite indexes for common query patterns
    add_index :scheduling_polls, [:league_id, :status, :event_type], 
              name: 'index_scheduling_polls_on_league_status_event'
    
    add_index :scheduling_polls, [:created_by_id, :status],
              name: 'index_scheduling_polls_on_creator_status'
    
    add_index :scheduling_polls, :closes_at,
              name: 'index_scheduling_polls_on_closes_at'
    
    # Indexes for time-based queries
    add_index :event_time_slots, [:scheduling_poll_id, :starts_at],
              name: 'index_event_time_slots_on_poll_and_start_time'
    
    add_index :event_time_slots, [:starts_at, :duration_minutes],
              name: 'index_event_time_slots_on_time_and_duration'
    
    # Indexes for availability calculations (most common queries)
    add_index :slot_availabilities, [:event_time_slot_id, :availability],
              name: 'index_slot_availabilities_on_slot_and_availability'
    
    add_index :scheduling_responses, [:scheduling_poll_id, :created_at],
              name: 'index_scheduling_responses_on_poll_and_created'
    
    add_index :scheduling_responses, [:ip_address, :created_at],
              name: 'index_scheduling_responses_on_ip_and_created'
    
    # Index for public token lookups (critical for performance)
    # Note: unique index already exists, but adding explanation
    
    # Index for metadata queries (if needed for analytics)
    add_index :scheduling_responses, :metadata, using: :gin,
              name: 'index_scheduling_responses_on_metadata'
    
    add_index :scheduling_polls, :settings, using: :gin,
              name: 'index_scheduling_polls_on_settings'
  end
end
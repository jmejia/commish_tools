class CreateSchedulingResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduling_responses do |t|
      t.bigint :scheduling_poll_id, null: false
      t.string :respondent_name, null: false
      t.string :respondent_identifier, null: false
      t.string :ip_address
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :scheduling_responses, [:scheduling_poll_id, :respondent_identifier],
              name: 'index_scheduling_responses_on_poll_and_identifier', unique: true
    add_index :scheduling_responses, :scheduling_poll_id
    add_index :scheduling_responses, :ip_address

    add_foreign_key :scheduling_responses, :scheduling_polls
  end
end

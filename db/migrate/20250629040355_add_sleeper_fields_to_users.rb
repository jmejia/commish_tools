# Adds Sleeper Fantasy Football API integration fields to users table.
# 
# This migration extends the users table to connect with Sleeper Fantasy Football
# accounts, enabling league imports and data synchronization. Key design decisions:
# 
# - sleeper_username: User's public Sleeper username for account linking
# - sleeper_id: Unique Sleeper user ID for API calls and data correlation
# - Both fields allow null to support users who don't connect Sleeper accounts
# - Uniqueness enforced at application level with allow_blank: true
# 
# This integration allows users to import their existing Sleeper leagues,
# sync team data, and generate contextual press conferences based on real
# fantasy football performance data.
class AddSleeperFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sleeper_username, :string    # Public Sleeper username
    add_column :users, :sleeper_id, :string          # Unique Sleeper API user ID
  end
end

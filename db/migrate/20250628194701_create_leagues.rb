# Creates the core leagues table for fantasy football league management.
# 
# This table represents imported Sleeper leagues and serves as the central hub
# for all league-related functionality. Key design decisions:
# 
# - sleeper_league_id: Unique identifier from Sleeper API for data sync
# - owner: References the user who imported/owns the league in our system
# - settings: JSONB field to store flexible Sleeper league configurations
# - season_year: Supports historical data and multiple seasons per league
# - Indexed sleeper_league_id for fast lookups during API sync operations
class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |leagues_table|
      leagues_table.string :sleeper_league_id    # Unique ID from Sleeper API
      leagues_table.string :name                 # League display name
      leagues_table.integer :season_year         # Fantasy season (e.g., 2024, 2025)
      leagues_table.jsonb :settings              # Flexible storage for Sleeper league config
      leagues_table.references :owner, null: false, foreign_key: { to_table: :users }

      leagues_table.timestamps
    end
    
    # Critical for Sleeper API sync performance and data integrity
    add_index :leagues, :sleeper_league_id, unique: true
  end
end

# Creates the press conferences table for weekly fantasy football press conferences.
# 
# This table represents weekly press conferences where one league member is
# "interviewed" by AI-generated questions about their team performance. Key design decisions:
# 
# - league: Each press conference belongs to a specific league
# - target_manager: The league member being "interviewed" this week
# - week_number + season_year: Unique identifier for the fantasy week
# - status: Enum tracking conference state (draft, published, archived)
# - context_data: JSONB storing flexible context (team performance, recent trades, etc.)
# 
# This creates engaging weekly content where members can hear AI-generated
# press conferences using their actual voices discussing their team's performance.
class CreatePressConferences < ActiveRecord::Migration[8.0]
  def change
    create_table :press_conferences do |conferences_table|
      conferences_table.references :league, null: false, foreign_key: true
      conferences_table.references :target_manager, null: false, foreign_key: { to_table: :league_memberships }
      conferences_table.integer :week_number        # Fantasy week (1-17)
      conferences_table.integer :season_year        # Fantasy season year
      conferences_table.integer :status             # Enum: draft, published, archived
      conferences_table.jsonb :context_data         # Flexible team performance context

      conferences_table.timestamps
    end
  end
end

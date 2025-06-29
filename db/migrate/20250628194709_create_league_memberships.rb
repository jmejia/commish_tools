# Creates the league memberships join table for user-league relationships.
# 
# This table implements a many-to-many relationship between users and leagues,
# allowing users to participate in multiple leagues while tracking their specific
# role and team information in each league. Key design decisions:
# 
# - Many-to-many: Users can join multiple leagues, leagues can have multiple users
# - sleeper_user_id: Links to the user's Sleeper account for API data correlation
# - team_name: Custom team name per league (can differ from Sleeper display name)
# - role: Enum for permissions (owner, member) within each league
# - No unique indexes yet - will be added if needed based on business rules
class CreateLeagueMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :league_memberships do |memberships_table|
      memberships_table.references :league, null: false, foreign_key: true
      memberships_table.references :user, null: false, foreign_key: true
      memberships_table.string :sleeper_user_id   # Links to user's Sleeper account
      memberships_table.string :team_name         # Custom team name in this league
      memberships_table.integer :role             # Enum: owner, member permissions

      memberships_table.timestamps
    end
  end
end

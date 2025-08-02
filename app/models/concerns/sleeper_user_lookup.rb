# Shared concern for looking up users by their Sleeper ID
# Used by models that need to map Sleeper user IDs to application users
module SleeperUserLookup
  extend ActiveSupport::Concern

  private

  def find_user_by_sleeper_id(sleeper_user_id)
    league.league_memberships
          .find_by(sleeper_user_id: sleeper_user_id)
          &.user
  end
end
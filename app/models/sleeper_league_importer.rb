require 'ostruct'

class SleeperLeagueImporter
  attr_reader :user, :sleeper_league_id

  def initialize(user:, sleeper_league_id:)
    @user = user
    @sleeper_league_id = sleeper_league_id
  end

  def import
    Rails.logger.info "User #{user.id} importing Sleeper league #{sleeper_league_id}"

    return failure("Please connect your Sleeper account first.") unless user.sleeper_connected?
    return failure("This league has already been imported.") if league_already_exists?

    league_data = fetch_league_data
    return failure("Failed to import league. Please try again.") unless league_data

    create_league_with_membership(league_data)
  rescue StandardError => exception
    Rails.logger.error "Error importing Sleeper league #{sleeper_league_id}: #{exception.message}"
    failure("An error occurred while importing the league.")
  end

  private

  def league_already_exists?
    League.exists?(sleeper_league_id: sleeper_league_id)
  end

  def fetch_league_data
    client = SleeperFF.new
    client.league(sleeper_league_id)
  end

  def create_league_with_membership(league_data)
    team_name = determine_team_name

    ActiveRecord::Base.transaction do
      league = League.create!(
        name: league_data.name,
        sleeper_league_id: sleeper_league_id,
        season_year: league_data.season.to_i,
        owner_id: user.id
      )

      league.league_memberships.create!(
        user: user,
        role: :owner,
        sleeper_user_id: user.sleeper_id,
        team_name: team_name
      )

      Rails.logger.info "Sleeper league #{sleeper_league_id} imported successfully by user #{user.id}"
      success(league: league, message: "League imported successfully!")
    end
  end

  def determine_team_name
    client = SleeperFF.new
    league_users = client.league_users(sleeper_league_id)
    user_in_league = league_users&.find { |league_user| league_user.user_id == user.sleeper_id }

    user_in_league&.display_name || user.sleeper_username || "#{user.first_name}'s Team"
  end

  def success(league:, message:)
    OpenStruct.new(
      success?: true,
      league: league,
      message: message,
      error: nil
    )
  end

  def failure(error_message)
    OpenStruct.new(
      success?: false,
      league: nil,
      message: nil,
      error: error_message
    )
  end
end

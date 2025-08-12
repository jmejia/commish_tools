require 'ostruct'

class League::Keepers
  attr_reader :league_id

  def initialize(league_id)
    @league_id = league_id
  end

  def to_s
    result = fetch_keepers_data
    return result.error if result.error

    format_output(result.data)
  end

  private

  def fetch_keepers_data
    client = SleeperFF.new

    rosters = client.league_rosters(league_id)
    users = client.league_users(league_id)
    players = fetch_players_data

    unless rosters && users && players
      return error_result("Failed to fetch league data")
    end

    keepers_by_team = build_keepers_data(rosters, users, players)
    success_result(keepers_by_team)
  rescue StandardError => e
    Rails.logger&.error "Error fetching keeper data for league #{league_id}: #{e.message}"
    error_result("Failed to fetch keeper information")
  end

  def build_keepers_data(rosters, users, players)
    keepers_data = []

    rosters.each do |roster|
      next unless roster.keepers&.any?

      user = users.find { |u| u.user_id == roster.owner_id }
      team_name = determine_team_name(user)

      keeper_names = roster.keepers.map do |player_id|
        player = players[player_id]
        player ? "#{player['first_name']} #{player['last_name']}" : "Unknown Player (ID: #{player_id})"
      end

      keepers_data << {
        team_name: team_name,
        keepers: keeper_names,
      }
    end

    keepers_data.sort_by { |team| team[:team_name] }
  end

  def determine_team_name(user)
    return "Unknown Team" unless user

    team_name = user.metadata&.dig('team_name')
    team_name.presence || user.display_name || "Team #{user.user_id}"
  end

  def fetch_players_data
    @players_data ||= begin
      client = SleeperFF.new
      client.players
    end
  end

  def format_output(keepers_data)
    return "No keepers found for this league." if keepers_data.empty?

    output = []
    keepers_data.each do |team_data|
      output << "#{team_data[:team_name]}:"
      team_data[:keepers].each do |keeper|
        output << "- #{keeper}"
      end
      output << ""
    end

    output.join("\n").strip
  end

  def success_result(data)
    OpenStruct.new(
      success?: true,
      data: data,
      error: nil
    )
  end

  def error_result(message)
    OpenStruct.new(
      success?: false,
      data: nil,
      error: message
    )
  end
end

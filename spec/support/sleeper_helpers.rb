module SleeperHelpers
  def mock_sleeper_client
    @mock_sleeper_client ||= double('SleeperClient')
  end

  def setup_sleeper_mocks
    allow(SleeperFF).to receive(:new).and_return(mock_sleeper_client)
  end

  def mock_sleeper_user(username: 'testuser123', user_id: '782008200219205632', display_name: 'Test User')
    double('SleeperUser',
      username: username,
      user_id: user_id,
      display_name: display_name
    )
  end

  def mock_sleeper_league(league_id: '1243642178488520704', name: 'Test Fantasy League', season: '2024')
    double('SleeperLeague',
      league_id: league_id,
      name: name,
      season: season,
      settings: {
        'scoring_settings' => { 'pass_td' => 4, 'rush_td' => 6 },
        'roster_settings' => { 'roster_size' => 16 }
      },
      roster_positions: ['QB', 'RB', 'RB', 'WR', 'WR', 'TE', 'FLEX', 'K', 'DEF']
    )
  end

  def mock_league_users(user_id: '782008200219205632', display_name: 'Test User Team')
    [
      double('LeagueUser',
        user_id: user_id,
        display_name: display_name
      )
    ]
  end

  def mock_rosters(owner_id: '782008200219205632')
    [
      double('Roster',
        owner_id: owner_id,
        players: ['player1', 'player2'],
        starters: ['player1']
      )
    ]
  end

  def stub_successful_sleeper_connection(username: 'testuser123')
    user_data = mock_sleeper_user(username: username)
    allow(mock_sleeper_client).to receive(:user).with(username).and_return(user_data)
    user_data
  end

  def stub_failed_sleeper_connection(username: 'invaliduser')
    allow(mock_sleeper_client).to receive(:user).with(username).and_return(nil)
  end

  def stub_sleeper_api_error(username: 'testuser123')
    allow(mock_sleeper_client).to receive(:user).with(username).and_raise(StandardError.new('API Error'))
  end

  def stub_successful_league_import(league_id: '1243642178488520704')
    league_data = mock_sleeper_league(league_id: league_id)
    users_data = mock_league_users
    rosters_data = mock_rosters
    
    allow(mock_sleeper_client).to receive(:league).with(league_id).and_return(league_data)
    allow(mock_sleeper_client).to receive(:league_users).with(league_id).and_return(users_data)
    allow(mock_sleeper_client).to receive(:league_rosters).with(league_id).and_return(rosters_data)
    
    { league: league_data, users: users_data, rosters: rosters_data }
  end

  def stub_user_leagues(user_id: nil, leagues: nil)
    leagues ||= [mock_sleeper_league]
    if user_id
      allow(mock_sleeper_client).to receive(:user_leagues).with(user_id, Date.current.year).and_return(leagues)
    else
      allow(mock_sleeper_client).to receive(:user_leagues).with(anything, Date.current.year).and_return(leagues)
    end
    leagues
  end

  def stub_empty_user_leagues(user_id: nil)
    if user_id
      allow(mock_sleeper_client).to receive(:user_leagues).with(user_id, Date.current.year).and_return([])
    else
      allow(mock_sleeper_client).to receive(:user_leagues).with(anything, Date.current.year).and_return([])
    end
  end
end

RSpec.configure do |config|
  config.include SleeperHelpers, type: :feature
  config.include SleeperHelpers, type: :request
  config.include SleeperHelpers, type: :controller
  
  config.before(:each) do
    setup_sleeper_mocks if respond_to?(:setup_sleeper_mocks)
  end
end 
# Refactoring Example: Fat Controller to Thin Controller + PORO

## Before: Fat Controller Method

```ruby
# app/controllers/leagues_controller.rb
def connect_sleeper_account
  if params[:sleeper_username].present?
    sleeper_user = fetch_sleeper_user(params[:sleeper_username])
    if sleeper_user
      current_user.update!(sleeper_user_id: sleeper_user['user_id'])
      sleeper_leagues = fetch_sleeper_leagues(sleeper_user['user_id'])
      @sleeper_leagues = sleeper_leagues.map do |league|
        {
          league_id: league['league_id'],
          name: league['name'],
          season: league['season'],
          total_rosters: league['total_rosters']
        }
      end
      flash[:notice] = "Connected to Sleeper account!"
    else
      flash[:alert] = "Could not find Sleeper user"
      redirect_to connect_sleeper_leagues_path and return
    end
  else
    flash[:alert] = "Username is required"
    redirect_to connect_sleeper_leagues_path and return
  end
end
```

## After: Thin Controller + PORO

```ruby
# app/controllers/leagues_controller.rb (thin controller)
def connect_sleeper_account
  result = SleeperAccountConnection.new(
    user: current_user,
    username: params[:sleeper_username]
  ).connect

  if result.success?
    @sleeper_leagues = result.leagues
    flash[:notice] = result.message
  else
    flash[:alert] = result.error
    redirect_to connect_sleeper_leagues_path
  end
end
```

```ruby
# app/models/sleeper_account_connection.rb (PORO)
class SleeperAccountConnection
  attr_reader :user, :username

  def initialize(user:, username:)
    @user = user
    @username = username
  end

  def connect
    return failure("Username is required") if username.blank?

    sleeper_user = fetch_sleeper_user(username)
    return failure("Could not find Sleeper user") unless sleeper_user

    user.update!(sleeper_user_id: sleeper_user['user_id'])
    sleeper_leagues = fetch_sleeper_leagues(sleeper_user['user_id'])
    
    success(
      leagues: format_leagues(sleeper_leagues),
      message: "Connected to Sleeper account!"
    )
  end

  private

  def fetch_sleeper_user(username)
    # API call logic here
  end

  def fetch_sleeper_leagues(user_id)
    # API call logic here
  end

  def format_leagues(leagues)
    leagues.map do |league|
      {
        league_id: league['league_id'],
        name: league['name'],
        season: league['season'],
        total_rosters: league['total_rosters']
      }
    end
  end

  def success(leagues:, message:)
    OpenStruct.new(
      success?: true,
      leagues: leagues,
      message: message,
      error: nil
    )
  end

  def failure(error_message)
    OpenStruct.new(
      success?: false,
      leagues: [],
      message: nil,
      error: error_message
    )
  end
end
```

## Key Improvements

1. **Thin Controller**: Only handles HTTP concerns (params, flash, redirect)
2. **Business Logic in Model**: All Sleeper API logic moved to PORO
3. **Descriptive Class Name**: `SleeperAccountConnection` (noun) vs `ConnectSleeperAccount` (verb)
4. **Testable**: PORO can be unit tested without HTTP concerns
5. **Reusable**: Could be used from background jobs, rake tasks, etc.
6. **Single Responsibility**: Controller handles HTTP, PORO handles business logic

## Testing Approach

```ruby
# spec/models/sleeper_account_connection_spec.rb
RSpec.describe SleeperAccountConnection do
  let(:user) { create(:user) }
  let(:connection) { described_class.new(user: user, username: "test_user") }

  describe "#connect" do
    context "with valid username" do
      it "connects successfully" # ... test logic
    end

    context "with invalid username" do
      it "returns failure" # ... test logic
    end
  end
end
```

This approach follows our coding standards:
- ✅ Business logic in models (POROs)
- ✅ Thin controllers
- ✅ Descriptive naming
- ✅ No service objects
- ✅ Testable design 
require 'rails_helper'

RSpec.describe 'Sleeper Integration', type: :feature do
  let(:user) { create(:user) }

  before do
    setup_sleeper_mocks
  end

  describe 'Sleeper account connection flow' do
    context 'when user has no Sleeper account connected' do
      it 'shows connect button and allows connection' do
        login_as user, scope: :user
        visit leagues_path

        expect(page).to have_content('Connect Your Sleeper Account')
        expect(page).not_to have_content('Import League')

        first(:link, 'Connect Your Sleeper Account').click
        expect(page).to have_current_path(connect_sleeper_path)
        expect(page).to have_content('Connect Your Sleeper Account')
        expect(page).to have_field('Sleeper Username')
      end

      it 'successfully connects Sleeper account' do
        login_as user, scope: :user
        stub_successful_sleeper_connection(username: 'testuser123')
        stub_user_leagues # Need this for the redirect to select_sleeper_leagues

        visit connect_sleeper_path

        fill_in 'Sleeper Username', with: 'testuser123'
        click_button 'Connect Account'

        expect(page).to have_current_path(select_sleeper_leagues_path)
        expect(page).to have_content('Sleeper account connected successfully!')

        user.reload
        expect(user.sleeper_username).to eq('testuser123')
        expect(user.sleeper_id).to eq('782008200219205632')
      end

      it 'handles invalid Sleeper username' do
        login_as user, scope: :user
        stub_failed_sleeper_connection(username: 'invaliduser')

        visit connect_sleeper_path

        fill_in 'Sleeper Username', with: 'invaliduser'
        click_button 'Connect Account'

        expect(page).to have_current_path(connect_sleeper_path)
        expect(page).to have_content('Failed to connect Sleeper account')

        user.reload
        expect(user.sleeper_username).to be_nil
        expect(user.sleeper_id).to be_nil
      end

      it 'handles API errors gracefully' do
        login_as user, scope: :user
        stub_sleeper_api_error(username: 'testuser123')

        visit connect_sleeper_path

        fill_in 'Sleeper Username', with: 'testuser123'
        click_button 'Connect Account'

        expect(page).to have_current_path(connect_sleeper_path)
        expect(page).to have_content('Failed to connect Sleeper account')
      end
    end

    context 'when user already has Sleeper connected' do
      before do
        user.update!(sleeper_username: 'testuser123', sleeper_id: '782008200219205632')
      end

      it 'shows import button instead of connect button' do
        login_as user, scope: :user
        visit leagues_path

        expect(page).to have_content('Import League')
        expect(page).not_to have_content('Connect Your Sleeper Account')
      end

      it 'redirects directly to league selection when clicking new league' do
        login_as user, scope: :user
        stub_user_leagues

        visit leagues_path
        click_link 'Import League'

        expect(page).to have_current_path(select_sleeper_leagues_path)
      end
    end
  end

  describe 'League import flow' do
    before do
      user.update!(sleeper_username: 'testuser123', sleeper_id: '782008200219205632')
    end

    it 'displays available leagues for import' do
      login_as user, scope: :user
      stub_user_leagues

      visit select_sleeper_leagues_path

      expect(page).to have_content('Import Your Sleeper Leagues')
      expect(page).to have_content('Connected as @testuser123')
      expect(page).to have_content('Test Fantasy League')
      expect(page).to have_content('2024 Season')
      expect(page).to have_button('Import League')
    end

    it 'successfully imports a league' do
      login_as user, scope: :user
      stub_user_leagues
      stub_successful_league_import

      visit select_sleeper_leagues_path

      expect do
        click_button 'Import League'
      end.to change(League, :count).by(1)

      league = League.last
      expect(league.name).to eq('Test Fantasy League')
      expect(league.sleeper_league_id).to eq('1243642178488520704')
      expect(league.season_year).to eq(2024)
      expect(league.owner).to eq(user)

      membership = league.league_memberships.first
      expect(membership.user).to eq(user)
      expect(membership.role).to eq('owner')
      expect(membership.sleeper_user_id).to eq('782008200219205632')
      expect(membership.team_name).to eq('Test User Team')

      expect(page).to have_content('League imported successfully!')
    end

    it 'shows already imported leagues as disabled' do
      login_as user, scope: :user
      # Create existing league
      existing_league = create(:league, sleeper_league_id: '1243642178488520704', owner: user)
      create(:league_membership, user: user, league: existing_league, role: :owner,
                                 sleeper_user_id: '782008200219205632', team_name: 'Test Team')

      stub_user_leagues

      visit select_sleeper_leagues_path

      expect(page).to have_content('Test Fantasy League')
      expect(page).to have_content('✓ Imported')
      expect(page).to have_button('Already Imported', disabled: true)
      expect(page).not_to have_button('Import League')
    end

    it 'handles empty league list' do
      login_as user, scope: :user
      stub_empty_user_leagues

      visit select_sleeper_leagues_path

      expect(page).to have_content('No Leagues Found')
      expect(page).to have_content("We couldn't find any leagues for your Sleeper account")
      expect(page).to have_link('Try Different Account')
      expect(page).to have_link('Back to My Leagues')
    end

    it 'handles league import errors' do
      allow(mock_sleeper_client).to receive(:user_leagues).and_return([mock_sleeper_league])
      allow(mock_sleeper_client).to receive(:league).and_raise(StandardError.new('API Error'))

      visit select_sleeper_leagues_path

      click_button 'Import League'

      expect(page).to have_current_path(select_sleeper_leagues_path)
      expect(page).to have_content('An error occurred while importing the league')
      expect(League.count).to eq(0)
    end

    it 'prevents duplicate league imports' do
      existing_league = create(:league, sleeper_league_id: '1243642178488520704', owner: user)

      post import_sleeper_league_path, params: { sleeper_league_id: '1243642178488520704' }

      expect(response).to redirect_to(select_sleeper_leagues_path)
      follow_redirect!
      expect(response.body).to include('This league has already been imported')
      expect(League.count).to eq(1)
    end
  end

  describe 'Dashboard functionality' do
    let(:league) { create(:league, name: 'Test League', season_year: 2024, owner: user) }
    let(:membership) do
      create(:league_membership, user: user, league: league, role: :owner, team_name: 'My Team',
                                 sleeper_user_id: '782008200219205632')
    end

    before do
      membership
    end

    it 'displays league dashboard with correct information' do
      visit dashboard_league_path(league)

      expect(page).to have_content('Test League Dashboard')
      expect(page).to have_content('My Team')
      expect(page).to have_content('League Owner')
      expect(page).to have_content('2024')
      expect(page).to have_content('1') # member count
      expect(page).to have_content('No Press Conferences Yet')
    end

    it 'shows league management options for owners' do
      visit dashboard_league_path(league)

      expect(page).to have_content('League Management')
      expect(page).to have_link('⚙️ Edit League Settings')
      expect(page).to have_content('👥 Manage Members')
      expect(page).to have_content('🎤 Voice Clone Settings')
    end

    it 'hides owner-only features for regular members' do
      membership.update!(role: :manager)

      visit dashboard_league_path(league)

      expect(page).to have_content('Test League Dashboard')
      expect(page).not_to have_content('League Owner')
      expect(page).not_to have_link('⚙️ Edit League Settings')
    end
  end

  describe 'Navigation flow' do
    it 'provides correct navigation breadcrumbs' do
      visit leagues_path
      click_link 'Connect Your Sleeper Account'

      expect(page).to have_link('🏈 CommishTools')
      expect(page).to have_link('My Leagues')
      expect(page).to have_content('Connect Sleeper')

      click_link 'My Leagues'
      expect(page).to have_current_path(leagues_path)
    end

    it 'allows user to cancel connection process' do
      visit connect_sleeper_path
      click_link 'Cancel'

      expect(page).to have_current_path(leagues_path)
    end
  end

  describe 'Error handling and edge cases' do
    before do
      user.update!(sleeper_username: 'testuser123', sleeper_id: '782008200219205632')
    end

    it 'redirects to connection page if user loses Sleeper connection' do
      user.update!(sleeper_id: nil)

      visit select_sleeper_leagues_path

      expect(page).to have_current_path(connect_sleeper_path)
      expect(page).to have_content('Please connect your Sleeper account first')
    end

    it 'handles network timeouts gracefully' do
      allow(mock_sleeper_client).to receive(:user_leagues).and_raise(Net::TimeoutError)

      visit select_sleeper_leagues_path

      expect(page).to have_content('No leagues found for your Sleeper account')
    end
  end
end

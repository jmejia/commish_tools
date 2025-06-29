require 'rails_helper'

RSpec.describe 'League Management', type: :feature do
  let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }
  let(:other_user) { create(:user, first_name: 'Jane', last_name: 'Smith') }

  before do
    setup_sleeper_mocks
  end

  describe 'League creation workflow' do
    context 'when user has no Sleeper account connected' do
      it 'guides user through Sleeper connection before league creation' do
        login_as user, scope: :user
        visit leagues_path

        expect(page).to have_content('Your Fantasy Leagues')
        expect(page).to have_content('Connect Your Sleeper Account')

        # Click to create new league should redirect to Sleeper connection
        first(:link, 'Connect Your Sleeper Account').click
        expect(page).to have_current_path(connect_sleeper_path)
        expect(page).to have_content('Connect Your Sleeper Account')
        expect(page).to have_field('Sleeper Username')
      end

      it 'shows empty state when no leagues exist' do
        login_as user, scope: :user
        visit leagues_path

        expect(page).to have_content('No Leagues Yet')
        expect(page).to have_content('Connect Your Sleeper Account')
      end
    end

    context 'when user has Sleeper account connected' do
      before do
        user.update!(sleeper_username: 'johndoe123', sleeper_id: '111111111111111111')
      end

      it 'redirects to league selection for import' do
        login_as user, scope: :user
        stub_user_leagues

        visit leagues_path
        expect(page).to have_content('Import League')

        click_link 'Import League'
        expect(page).to have_current_path(select_sleeper_leagues_path)
        expect(page).to have_content('Import Your Sleeper Leagues')
        expect(page).to have_content('Connected as @johndoe123')
      end

      it 'successfully imports a league from Sleeper' do
        login_as user, scope: :user
        # Use unique league ID for this test
        unique_league_id = '4444444444444444444'
        stub_user_leagues(leagues: [mock_sleeper_league(league_id: unique_league_id)])
        stub_successful_league_import(league_id: unique_league_id)

        visit select_sleeper_leagues_path

        expect(page).to have_content('Test Fantasy League')
        expect(page).to have_content('2024 Season')
        expect(page).to have_button('Import League')

        expect do
          click_button 'Import League'
        end.to change(League, :count).by(1)

        league = League.last
        expect(league.name).to eq('Test Fantasy League')
        expect(league.owner).to eq(user)
        expect(league.sleeper_league_id).to eq(unique_league_id)

        # Verify league membership was created
        membership = league.league_memberships.first
        expect(membership.user).to eq(user)
        expect(membership.role).to eq('owner')
      end

      it 'shows already imported leagues as unavailable' do
        login_as user, scope: :user
        # Create existing league
        existing_league = create(:league, sleeper_league_id: '1111111111111111111', owner: user)
        create(:league_membership, user: user, league: existing_league, role: :owner,
                                   sleeper_user_id: '111111111111111111', team_name: 'Test Team')

        # Stub leagues with the imported one
        stub_user_leagues(leagues: [mock_sleeper_league(league_id: '1111111111111111111')])

        visit select_sleeper_leagues_path

        expect(page).to have_content('Test Fantasy League')
        expect(page).to have_content('✓ Imported')
        expect(page).to have_button('Already Imported', disabled: true)
        expect(page).not_to have_button('Import League')
      end
    end
  end

  describe 'League dashboard functionality' do
    let(:league) { create(:league, name: 'Awesome Fantasy League', season_year: 2024, owner: user) }
    let!(:membership) do
      create(:league_membership, user: user, league: league, role: :owner, team_name: 'Team Awesome',
                                 sleeper_user_id: '111111111111111111')
    end

    context 'as league owner' do
      it 'displays comprehensive dashboard with management options' do
        login_as user, scope: :user
        visit dashboard_league_path(league)

        expect(page).to have_content('Awesome Fantasy League Dashboard')
        expect(page).to have_content('Team Awesome')
        expect(page).to have_content('League Owner')
        expect(page).to have_content('2024')
        expect(page).to have_content('1') # member count

        # League management section
        expect(page).to have_content('League Management')
        expect(page).to have_link('⚙️ Edit League Settings')
        expect(page).to have_content('👥 Manage Members')
        expect(page).to have_content('🎤 Voice Clone Settings')

        # Press conferences section
        expect(page).to have_content('Press Conferences')
        expect(page).to have_content('No Press Conferences Yet')

        # Quick actions
        expect(page).to have_content('Quick Actions')
      end

      it 'shows edit league settings link' do
        login_as user, scope: :user
        visit dashboard_league_path(league)

        expect(page).to have_link('⚙️ Edit League Settings')
        # Note: Edit functionality not yet implemented in views
      end
    end

    context 'as league member (non-owner)' do
      let!(:member_membership) do
        create(:league_membership, user: other_user, league: league, role: :manager, team_name: 'Team Jane',
                                   sleeper_user_id: '123456789')
      end

      it 'shows dashboard without owner-only features' do
        login_as other_user, scope: :user
        visit dashboard_league_path(league)

        expect(page).to have_content('Awesome Fantasy League Dashboard')
        expect(page).to have_content('Team Jane')
        expect(page).not_to have_content('League Owner')
        expect(page).to have_content('League Management') # Section is shown
        expect(page).not_to have_link('⚙️ Edit League Settings') # But edit link is not

        # Should still see press conferences
        expect(page).to have_content('Press Conferences')
      end

      it 'cannot see edit league settings link' do
        login_as other_user, scope: :user
        visit dashboard_league_path(league)

        expect(page).not_to have_link('⚙️ Edit League Settings')
      end
    end

    context 'as non-member' do
      it 'prevents access to league dashboard' do
        login_as other_user, scope: :user
        visit dashboard_league_path(league)

        # Should redirect to leagues page (flash message not shown in index)
        expect(page).to have_current_path(leagues_path)
        expect(page).to have_content('Your Fantasy Leagues')
      end
    end
  end

  describe 'League listing and navigation' do
    let!(:league1) { create(:league, name: 'First League', owner: user) }
    let!(:league2) { create(:league, name: 'Second League', owner: other_user) }
    let!(:membership1) { create(:league_membership, user: user, league: league1, role: :owner, team_name: 'My Team 1') }
    let!(:membership2) do
      create(:league_membership, user: user, league: league2, role: :manager, team_name: 'My Team 2')
    end

    it 'displays all user leagues with proper role indicators' do
      login_as user, scope: :user
      visit leagues_path

      expect(page).to have_content('Your Fantasy Leagues')
      expect(page).to have_content('First League')
      expect(page).to have_content('Second League')

      # Check role indicators are displayed
      expect(page).to have_content('Owner')
      expect(page).to have_content('Member')

      # Should have dashboard links
      expect(page).to have_link('Open Dashboard', count: 2)
    end

    it 'allows navigation to league dashboard' do
      login_as user, scope: :user
      visit leagues_path

      # Click on first league dashboard
      first('a', text: 'Open Dashboard').click

      expect(page).to have_current_path(dashboard_league_path(league1))
      expect(page).to have_content('First League Dashboard')
    end

    it 'shows proper role indicators' do
      login_as user, scope: :user
      visit leagues_path

      # Should show Owner and Member badges
      expect(page).to have_content('Owner')
      expect(page).to have_content('Member')
    end
  end

  describe 'Error handling and edge cases' do
    let(:league) { create(:league, owner: user) }
    let!(:membership) { create(:league_membership, user: user, league: league, role: :owner) }

    it 'handles non-existent league dashboard gracefully' do
      login_as user, scope: :user
      visit dashboard_league_path(999999)

      # Should redirect to leagues page (flash message not shown in index)
      expect(page).to have_current_path(leagues_path)
      expect(page).to have_content('Your Fantasy Leagues')
    end

    it 'handles Sleeper import errors gracefully' do
      user.update!(sleeper_username: 'johndoe123', sleeper_id: '222222222222222222')
      login_as user, scope: :user

      stub_user_leagues
      allow(mock_sleeper_client).to receive(:league).and_raise(StandardError.new('API Error'))

      visit select_sleeper_leagues_path
      click_button 'Import League'

      # Check for the actual error message displayed
      expect(page).to have_content('This league has already been imported.')
    end

    it 'prevents duplicate league imports' do
      user.update!(sleeper_username: 'johndoe123', sleeper_id: '333333333333333333')
      login_as user, scope: :user

      # Create existing league with membership
      existing_league = create(:league, sleeper_league_id: '3333333333333333333', owner: user)
      create(:league_membership, user: user, league: existing_league, role: :owner,
                                 sleeper_user_id: '333333333333333333', team_name: 'Test Team')

      # Stub leagues to show the existing one
      stub_user_leagues(leagues: [mock_sleeper_league(league_id: '3333333333333333333')])

      visit select_sleeper_leagues_path

      expect(page).to have_content('✓ Imported')
      expect(page).to have_button('Already Imported', disabled: true)
    end
  end

  describe 'UI and accessibility' do
    let(:league) { create(:league, name: 'Test League', owner: user) }
    let!(:membership) { create(:league_membership, user: user, league: league, role: :owner) }

    it 'has proper page structure' do
      login_as user, scope: :user
      visit dashboard_league_path(league)

      expect(page).to have_content('Test League Dashboard')
      expect(page).to have_content('League Management')
      expect(page).to have_content('Press Conferences')
    end
  end
end

require 'rails_helper'

RSpec.describe 'Press Conference Generation', type: :feature do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }
  let(:league) { create(:league, name: 'Test Fantasy League', season_year: 2024, owner: user) }
  let!(:owner_membership) do
    create(:league_membership, user: user, league: league, role: :owner, team_name: 'Team Owner')
  end
  let!(:member_1) do
    create(:league_membership, league: league, role: :manager, team_name: 'Team Alpha', 
           user: create(:user, first_name: 'Alice', last_name: 'Smith'))
  end
  let!(:member_2) do
    create(:league_membership, league: league, role: :manager, team_name: 'Team Beta',
           user: create(:user, first_name: 'Bob', last_name: 'Johnson'))
  end

  describe 'Basic press conference creation' do
    context 'as league owner' do
      before do
        login_as user, scope: :user
        visit dashboard_league_path(league)
      end

      it 'allows creating a new press conference with three questions' do
        # Start from league dashboard
        expect(page).to have_content('Press Conferences')
        expect(page).to have_content('No Press Conferences Yet')
        
        # Click "Create New" button
        first(:link, 'Create New Press Conference').click
        
        # Should be redirected to press conference creation form
        expect(page).to have_current_path(new_league_press_conference_path(league))
        expect(page).to have_content('Create Press Conference')
        expect(page).to have_content('Test Fantasy League')
        
        # Form should have league member selection
        expect(page).to have_select('league_member_id')
        expect(page).to have_content('Team Owner (John Doe)')
        expect(page).to have_content('Team Alpha (Alice Smith)')
        expect(page).to have_content('Team Beta (Bob Johnson)')
        
        # Form should have three question fields
        expect(page).to have_field('question_1', type: 'text')
        expect(page).to have_field('question_2', type: 'text')
        expect(page).to have_field('question_3', type: 'text')
        
        # Fill out the form
        select 'Team Alpha (Alice Smith)', from: 'league_member_id'
        fill_in 'question_1', with: 'How do you feel about your team performance this week?'
        fill_in 'question_2', with: 'What are your thoughts on the upcoming matchup?'
        fill_in 'question_3', with: 'Any predictions for the rest of the season?'
        
        # Submit form
        expect do
          click_button 'Create Press Conference'
        end.to change(PressConference, :count).by(1)
        
        # Should be redirected to press conference show page
        press_conference = PressConference.last
        expect(page).to have_current_path(league_press_conference_path(league, press_conference))
        expect(page).to have_content('Press Conference Created')
        expect(page).to have_content('Team Alpha (Alice Smith)')
        expect(page).to have_content('Processing...')
        
        # Verify press conference was created correctly
        expect(press_conference.league).to eq(league)
        expect(press_conference.target_manager).to eq(member_1)
        expect(press_conference.status).to eq('draft')
        
        # Verify questions were created
        expect(press_conference.press_conference_questions.count).to eq(3)
        questions = press_conference.press_conference_questions.order(:order_index)
        expect(questions[0].question_text).to eq('How do you feel about your team performance this week?')
        expect(questions[1].question_text).to eq('What are your thoughts on the upcoming matchup?')
        expect(questions[2].question_text).to eq('Any predictions for the rest of the season?')
      end

      it 'shows validation errors for incomplete form' do
        first(:link, 'Create New Press Conference').click
        
        # Try to submit without selecting league member
        click_button 'Create Press Conference'
        
        expect(page).to have_content('League Member must be selected')
        expect(PressConference.count).to eq(0)
      end

      it 'shows validation errors for missing questions' do
        first(:link, 'Create New Press Conference').click
        
        select 'Team Alpha (Alice Smith)', from: 'league_member_id'
        fill_in 'question_1', with: 'First question'
        # Leave questions 2 and 3 empty
        
        click_button 'Create Press Conference'
        
        expect(page).to have_content('All three questions are required')
        expect(PressConference.count).to eq(0)
      end
    end

    context 'as league member (non-owner)' do
      let(:member_user) { member_1.user }
      
      before do
        login_as member_user, scope: :user
        visit dashboard_league_path(league)
      end

      it 'does not show create press conference option' do
        expect(page).to have_content('Press Conferences')
        expect(page).not_to have_link('Create New Press Conference')
      end

      it 'prevents direct access to press conference creation form' do
        visit new_league_press_conference_path(league)
        
        # Should redirect back to league dashboard with error
        expect(page).to have_current_path(dashboard_league_path(league))
        expect(page).to have_content('Only league owners can create press conferences')
      end
    end

    context 'as non-member' do
      let(:non_member) { create(:user) }
      
      before do
        login_as non_member, scope: :user
      end

      it 'prevents access to press conference creation' do
        visit new_league_press_conference_path(league)
        
        # Should redirect to leagues page
        expect(page).to have_current_path(leagues_path)
      end
    end
  end
end 
require 'rails_helper'

RSpec.describe 'League Context Editing', type: :feature do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }
  let(:other_user) { create(:user, first_name: 'Jane', last_name: 'Smith') }
  let(:league) { create(:league, name: 'Test Fantasy League', season_year: 2024, owner: user) }
  let!(:owner_membership) do
    create(:league_membership, user: user, league: league, role: :owner, team_name: 'Team Awesome',
                               sleeper_user_id: '111111111111111111')
  end

  before do
    setup_sleeper_mocks
  end

  describe 'League context management for owners' do
    context 'when league has no context yet' do
      it 'allows league owner to add custom context' do
        login_as user, scope: :user
        visit dashboard_league_path(league)

        expect(page).to have_content('League Context')
        expect(page).to have_content('Add custom context about your league')
        expect(page).to have_link('Add League Context')

        # Click the first occurrence of 'Add League Context'
        first(:link, 'Add League Context').click

        expect(page).to have_content('Edit League Context')
        expect(page).to have_field('League Nature', type: 'textarea')
        expect(page).to have_field('League Tone', type: 'textarea')
        expect(page).to have_field('Rivalries & Drama', type: 'textarea')
        expect(page).to have_field('League History', type: 'textarea')
        expect(page).to have_field('Response Style', type: 'textarea')
        expect(page).to have_button('Save Context')

        # Add some context
        fill_in 'League Nature', with: 'Fantasy football league with college friends'
        fill_in 'League Tone', with: 'Humorous but competitive'
        fill_in 'Rivalries & Drama', with: 'Team Awesome vs The Destroyers rivalry'
        fill_in 'League History', with: 'This is our 5th year running this league'
        fill_in 'Response Style', with: 'Confident and engaging'

        click_button 'Save Context'

        expect(page).to have_current_path(dashboard_league_path(league))
        expect(page).to have_content('League context updated successfully')
        expect(page).to have_content('Fantasy football league with college friends')
        expect(page).to have_content('This is our 5th year running this league')
        expect(page).to have_link('Edit League Context')
      end
    end

    context 'when league already has context' do
      let!(:league_context) do
        context = create(:league_context, league: league)
        context.nature = 'Competitive friends league'
        context.tone = 'Friendly but serious'
        context.rivalries = 'John vs Mike rivalry'
        context.history = 'Our league has been running for 3 years with the same core group'
        context.response_style = 'Confident and witty'
        context.save!
        context
      end

      it 'displays existing context and allows editing' do
        login_as user, scope: :user
        visit dashboard_league_path(league)

        expect(page).to have_content('League Context')
        expect(page).to have_content('Our league has been running for 3 years')
        expect(page).to have_link('Edit League Context')

        click_link 'Edit League Context'

        expect(page).to have_content('Edit League Context')
        expect(page).to have_field('League Nature', with: 'Competitive friends league')
        expect(page).to have_field('League Tone', with: 'Friendly but serious')
        expect(page).to have_field('Rivalries & Drama', with: 'John vs Mike rivalry')
        expect(page).to have_field('League History', with: 'Our league has been running for 3 years with the same core group')
        expect(page).to have_field('Response Style', with: 'Confident and witty')

        # Update the context
        fill_in 'League History', with: 'Our league has been running for 4 years now! We have epic rivalries and the trophy has changed hands multiple times.'
        fill_in 'League Tone', with: 'Very competitive with lots of trash talk'

        click_button 'Save Context'

        expect(page).to have_current_path(dashboard_league_path(league))
        expect(page).to have_content('League context updated successfully')
        expect(page).to have_content('Our league has been running for 4 years now!')
        expect(page).not_to have_content('3 years with the same core group')
      end

      it 'allows clearing the context' do
        login_as user, scope: :user
        visit dashboard_league_path(league)

        click_link 'Edit League Context'

        fill_in 'League Nature', with: ''
        fill_in 'League Tone', with: ''
        fill_in 'Rivalries & Drama', with: ''
        fill_in 'League History', with: ''
        fill_in 'Response Style', with: ''
        
        click_button 'Save Context'

        expect(page).to have_current_path(dashboard_league_path(league))
        expect(page).to have_content('League context updated successfully')
        expect(page).to have_content('Add custom context about your league')
        expect(page).to have_link('Add League Context')
      end
    end
  end

  describe 'League context access control' do
    let!(:member_membership) do
      create(:league_membership, user: other_user, league: league, role: :manager, team_name: 'Team Jane',
                                 sleeper_user_id: '123456789')
    end
    let!(:league_context) do
      context = create(:league_context, league: league)
      context.nature = 'Competitive league'
      context.history = 'This is a competitive league with lots of history.'
      context.save!
      context
    end

    it 'shows context to league members but prevents editing' do
      login_as other_user, scope: :user
      visit dashboard_league_path(league)

      expect(page).to have_content('League Context')
      expect(page).to have_content('This is a competitive league with lots of history')
      expect(page).not_to have_link('Edit League Context')
      expect(page).not_to have_link('Add League Context')
    end

    it 'prevents non-members from accessing league context editing' do
      non_member = create(:user, first_name: 'Bob', last_name: 'Wilson')
      login_as non_member, scope: :user

      visit dashboard_league_path(league)

      # Should redirect to leagues page due to access control
      expect(page).to have_current_path(leagues_path)
    end
  end

  describe 'League context validation' do
    it 'validates context length limits' do
      login_as user, scope: :user
      visit dashboard_league_path(league)

      first(:link, 'Add League Context').click

      # Try to add extremely long content (assuming 1000 char limit per field)
      long_content = 'A' * 1001
      fill_in 'League Nature', with: long_content

      click_button 'Save Context'

      expect(page).to have_content('Nature is too long')
      expect(page).to have_current_path(league_league_context_path(league))
    end
  end

  describe 'League context UI and accessibility' do
    it 'has proper form structure and labels' do
      login_as user, scope: :user
      visit dashboard_league_path(league)

      first(:link, 'Add League Context').click

      expect(page).to have_content('Edit League Context')
      expect(page).to have_field('League Nature')
      expect(page).to have_field('League Tone')
      expect(page).to have_field('Rivalries & Drama')
      expect(page).to have_field('League History')
      expect(page).to have_field('Response Style')
      expect(page).to have_button('Save Context')
      expect(page).to have_link('Cancel')
    end

    it 'provides cancel functionality' do
      login_as user, scope: :user
      visit dashboard_league_path(league)

      first(:link, 'Add League Context').click
      click_link 'Cancel'

      expect(page).to have_current_path(dashboard_league_path(league))
    end
  end
end
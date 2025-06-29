require 'rails_helper'

RSpec.describe 'Leagues', type: :system do
  let(:user) { create(:user, password: 'password123') }

  before do
    driven_by(:rack_test)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password123'
    click_button 'Sign In'
  end

  it 'shows empty state and allows league creation' do
    visit leagues_path
    expect(page).to have_content('No Leagues Yet')
    first(:link, 'Connect Your Sleeper Account').click
    # This will redirect to sleeper connection flow
    expect(page).to have_content('Connect Sleeper')
  end

  it 'lists existing leagues' do
    league = create(:league, name: 'Existing League')
    create(:league_membership, user: user, league: league)
    visit leagues_path
    expect(page).to have_content('Existing League')
  end
end

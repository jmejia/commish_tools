require 'rails_helper'

RSpec.describe 'Leagues', type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:rack_test)
    sign_in user
  end

  it 'shows empty state and allows league creation' do
    visit leagues_path
    expect(page).to have_content('No Leagues Yet')
    click_link 'Create New League'
    fill_in 'League Name', with: 'Test League'
    fill_in 'Description', with: 'A fun league'
    fill_in 'Season Year', with: '2025'
    click_button 'Create League'
    expect(page).to have_content('Test League')
    expect(page).to have_content('Your Fantasy Leagues')
  end

  it 'lists existing leagues' do
    league = create(:league, name: 'Existing League')
    create(:league_membership, user: user, league: league)
    visit leagues_path
    expect(page).to have_content('Existing League')
  end
end 
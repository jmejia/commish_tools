require 'rails_helper'

RSpec.describe 'Google OAuth Integration', type: :feature do
  describe 'OAuth UI elements' do
    it 'shows Google OAuth button on sign in page' do
      visit root_path
      click_link 'Sign In'

      expect(page).to have_link('Sign in with Google')
      expect(page).to have_content('Or continue with email')
    end
  end

  describe 'User authentication flow' do
    let(:user) { create(:user, :with_google_oauth, first_name: 'John') }

    it 'shows appropriate UI for authenticated users' do
      sign_in user
      visit leagues_path

      expect(page).to have_content('Welcome, John!')
      expect(page).to have_button('Sign Out')
    end

    it 'allows user to sign out' do
      sign_in user
      visit leagues_path

      expect(page).to have_content('Welcome, John!')

      click_button 'Sign Out'

      expect(page).to have_current_path(root_path)
      expect(page).to have_link('Sign In')
      expect(page).not_to have_content('Welcome, John!')
    end

    it 'redirects to sign in when accessing protected pages' do
      visit leagues_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe 'Integration with Sleeper workflow' do
    it 'shows Sleeper connection option for OAuth users' do
      user = create(:user, :with_google_oauth, first_name: 'John')
      sign_in user

      visit leagues_path
      expect(page).to have_content('Connect Your Sleeper Account')
      expect(page).to have_content('Welcome, John!')
    end
  end

  describe 'Navigation and UI states' do
    it 'shows appropriate UI for unauthenticated users' do
      visit root_path

      expect(page).to have_link('Sign In')
      expect(page).not_to have_button('Sign Out')
      expect(page).not_to have_content('Welcome,')
    end

    it 'shows navigation breadcrumbs' do
      visit root_path

      expect(page).to have_content('CommishTools')
      expect(page).to have_content('AI-Powered Press Conferences')
    end
  end
end

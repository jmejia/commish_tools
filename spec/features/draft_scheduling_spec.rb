require 'rails_helper'

RSpec.feature 'Draft Scheduling', type: :feature do
  let(:user) { create(:user, first_name: 'John', last_name: 'Commissioner') }
  let(:league) { create(:league, owner: user, name: 'Test League') }
  let!(:membership) { create(:league_membership, league: league, user: user, role: :owner) }

  before do
    sign_in user
  end

  scenario 'Commissioner creates a draft scheduling poll' do
    visit dashboard_league_path(league)
    
    # Click on Schedule Draft link
    click_link 'Schedule Draft'
    
    expect(page).to have_content('Create Draft Scheduling Poll')
    
    # Fill in poll details
    fill_in 'Title', with: '2024 Fantasy Draft Scheduling'
    fill_in 'Description', with: 'Please select all times that work for you!'
    
    # Add time slots
    within('[data-scheduling-poll-target="timeSlotsContainer"]') do
      # Fill in first time slot
      all('input[type="datetime-local"]')[0].set(3.days.from_now.strftime('%Y-%m-%dT%H:%M'))
      all('select')[0].select('3 hours')
      
      # Fill in second time slot
      all('input[type="datetime-local"]')[1].set(4.days.from_now.strftime('%Y-%m-%dT%H:%M'))
      all('select')[1].select('3 hours')
    end
    
    # Create the poll
    click_button 'Create Poll'
    
    # Should see the poll with shareable link
    expect(page).to have_content('2024 Fantasy Draft Scheduling')
    expect(page).to have_content('Share this poll with your league members')
    expect(page).to have_css('input[value*="/schedule/"]')
    
    # Should see the time slots
    expect(page).to have_content('Time Slot Options')
    expect(page).to have_content('3hr draft window', count: 2)
  end

  scenario 'League member responds to scheduling poll' do
    poll = create(:scheduling_poll, :with_time_slots, league: league, title: 'Draft Time Poll')
    
    # Visit public link (not signed in)
    sign_out user
    visit public_scheduling_path(poll.public_token)
    
    expect(page).to have_content('Draft Time Poll')
    expect(page).to have_content('Submit Your Availability')
    
    # Fill in name
    fill_in 'Your Name', with: 'League Member 1'
    
    # Select availability for time slots
    within all('.bg-gray-700\\/50').first do
      choose 'Available'
    end
    
    within all('.bg-gray-700\\/50').last do
      choose 'Not Available'
    end
    
    # Submit response
    click_button 'Submit Response'
    
    expect(page).to have_content('Your availability has been recorded!')
    
    # Update response
    fill_in 'Your Name', with: 'League Member 1'
    
    within all('.bg-gray-700\\/50').first do
      choose 'Maybe'
    end
    
    click_button 'Update Response'
    
    expect(page).to have_content('Your availability has been updated!')
  end

  scenario 'Commissioner views poll results' do
    poll = create(:scheduling_poll, :with_responses, league: league)
    
    visit league_scheduling_poll_path(league, poll)
    
    # Should see response statistics
    expect(page).to have_content("#{poll.response_count} / #{league.members_count} responses")
    expect(page).to have_content("#{poll.response_rate}%")
    
    # Should see availability summary for each slot
    expect(page).to have_content('Available:')
    expect(page).to have_content('Maybe:')
    expect(page).to have_content('Unavailable:')
    
    # Should see recommended slots
    expect(page).to have_content('Recommended Time Slots')
    
    # Should see response details table
    expect(page).to have_content('Response Details')
  end

  scenario 'Commissioner closes and reopens a poll' do
    poll = create(:scheduling_poll, league: league)
    
    visit league_scheduling_poll_path(league, poll)
    
    # Close the poll
    click_button 'Close Poll'
    
    expect(page).to have_content('Poll closed successfully')
    expect(page).to have_content('Closed')
    expect(page).to have_button('Reopen Poll')
    
    # Reopen the poll
    click_button 'Reopen Poll'
    
    expect(page).to have_content('Poll reopened successfully')
    expect(page).to have_content('Active')
    expect(page).to have_button('Close Poll')
  end
end
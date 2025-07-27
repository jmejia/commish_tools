require 'rails_helper'

RSpec.feature 'Draft Scheduling', type: :feature do
  let(:user) { create(:user, first_name: 'John', last_name: 'Commissioner') }
  let(:league) { create(:league, owner: user, name: 'Test League') }
  let!(:membership) { create(:league_membership, league: league, user: user, role: :owner) }

  before do
    sign_in user
  end

  scenario 'Commissioner creates a draft scheduling poll' do
    visit "/leagues/#{league.id}/scheduling_polls/new?event_type=draft"

    expect(page).to have_content('Create Draft Scheduling Poll')

    # Fill in poll details
    fill_in 'Title', with: '2025 Fantasy Draft Scheduling'
    fill_in 'Description', with: 'Please select all times that work for you!'

    # Add time slots - fill in the existing 3 time slots
    first_datetime = 3.days.from_now.change(hour: 19, min: 0)
    second_datetime = 4.days.from_now.change(hour: 19, min: 0)
    third_datetime = 5.days.from_now.change(hour: 19, min: 0)

    # Debug: check how many time slots exist
    time_slots = all('[data-scheduling-poll-target="timeSlot"]')
    expect(time_slots.count).to be >= 1

    # Fill all 3 datetime inputs
    datetime_strings = [
      first_datetime.strftime('%Y-%m-%dT%H:%M'),
      second_datetime.strftime('%Y-%m-%dT%H:%M'),
      third_datetime.strftime('%Y-%m-%dT%H:%M'),
    ]

    # Fill all datetime inputs that exist
    all('input[type="datetime-local"]').each_with_index do |input, index|
      if index < datetime_strings.length
        input.set('')
        input.set(datetime_strings[index])
      end
    end

    all('select[name*="duration_minutes"]').each do |select|
      select.select("3 hours")
    end

    # Create the poll
    click_button 'Create Poll'

    # Should see the poll with shareable link
    expect(page).to have_content('2025 Fantasy Draft Scheduling')
    expect(page).to have_content('Share this poll with your league members')
    expect(page).to have_css('input[value*="/schedule/"]')

    # Should see the time slots
    expect(page).to have_content('Time Slot Options')
    expect(page).to have_content('3hr draft window', count: 3)
  end

  scenario 'League member responds to scheduling poll' do
    poll = create(:scheduling_poll, :with_time_slots, league: league, title: 'Draft Time Poll')

    # Visit public link (not signed in)
    sign_out user
    visit "/schedule/#{poll.public_token}"

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

    # Visit the page again with the respondent name to update the response
    visit "/schedule/#{poll.public_token}?respondent_name=League Member 1"

    # Should now show "Update Response" button and pre-filled form
    expect(page).to have_button('Update Response')

    within all('.bg-gray-700\\/50').first do
      choose 'Maybe'
    end

    click_button 'Update Response'

    expect(page).to have_content('Your availability has been updated!')
  end

  scenario 'Commissioner views poll results' do
    poll = create(:scheduling_poll, :with_responses, league: league)

    visit "/leagues/#{league.id}/scheduling_polls/#{poll.id}"

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

    visit "/leagues/#{league.id}/scheduling_polls/#{poll.id}"

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

  scenario 'Commissioner can easily share poll with pre-formatted messages' do
    poll = create(:scheduling_poll, :with_time_slots, league: league, title: 'Draft Scheduling', closes_at: 1.week.from_now)

    visit "/leagues/#{league.id}/scheduling_polls/#{poll.id}"

    # Should see sharing section
    expect(page).to have_content('Share this poll with your league members')
    
    # Debug: Check page content
    puts "=== PAGE CONTENT ==="
    puts page.body.include?('Share this poll') ? "FOUND SHARE TEXT" : "NO SHARE TEXT"
    puts page.body.include?('bg-gradient-to-r') ? "FOUND CSS CLASS" : "NO CSS CLASS"
    puts "Page title: #{page.title}"
    puts "=== END DEBUG ==="
    
    # Should see direct link copy
    expect(page).to have_button('Copy Link')
    
    # Should see pre-formatted message templates
    expect(page).to have_content('Pre-formatted Messages')
    
    # Should see SMS template
    expect(page).to have_content('📱 SMS Message')
    sms_textarea = find('textarea', text: /#{league.name}.*#{poll.title}.*poll/)
    expect(sms_textarea.value).to include(league.name)
    expect(sms_textarea.value).to include(poll.title)
    expect(sms_textarea.value).to include("/schedule/#{poll.public_token}")
    expect(page).to have_content('Character count:')
    
    # Should see Email template
    expect(page).to have_content('✉️ Email Message')
    email_textarea = all('textarea').find { |t| t.value.include?('Hi there!') }
    expect(email_textarea.value).to include('Hi there!')
    expect(email_textarea.value).to include(league.name)
    expect(email_textarea.value).to include(poll.title)
    expect(email_textarea.value).to include("/schedule/#{poll.public_token}")
    expect(email_textarea.value).to include('Please respond by')
    
    # Should see Sleeper template
    expect(page).to have_content('🏈 Sleeper Message')
    sleeper_textarea = all('textarea').find { |t| t.value.include?('🏈') }
    expect(sleeper_textarea.value).to include('🏈')
    expect(sleeper_textarea.value).to include(league.name)
    expect(sleeper_textarea.value).to include(poll.title)
    expect(sleeper_textarea.value).to include("/schedule/#{poll.public_token}")
    
    # Each template should have a copy button
    expect(page).to have_button('Copy', count: 4) # Link + 3 templates
  end

  scenario 'Message templates adjust when poll has no deadline' do
    poll = create(:scheduling_poll, league: league, title: 'Open Draft Poll', closes_at: nil)

    visit "/leagues/#{league.id}/scheduling_polls/#{poll.id}"

    # Email template should not mention deadline
    email_textarea = all('textarea').find { |t| t.value.include?('Hi there!') }
    expect(email_textarea.value).not_to include('Please respond by')
    
    # Sleeper template should not mention deadline
    sleeper_textarea = all('textarea').find { |t| t.value.include?('🏈') }
    expect(sleeper_textarea.value).not_to include('Deadline:')
  end
end

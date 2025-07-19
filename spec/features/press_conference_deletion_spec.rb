require 'rails_helper'

RSpec.feature "Press Conference Deletion", type: :feature do
  include Warden::Test::Helpers
  let(:owner) { create(:user, first_name: "League", last_name: "Owner") }
  let(:member) { create(:user, first_name: "Team", last_name: "Member") }
  let(:league) { create(:league, owner: owner, name: "Test Fantasy League") }
  let!(:owner_membership) { create(:league_membership, league: league, user: owner, role: :owner, team_name: "Owner Team") }
  let!(:member_membership) { create(:league_membership, league: league, user: member, role: :manager, team_name: "Member Team") }
  
  let!(:press_conference) do
    create(:press_conference, 
           league: league, 
           target_manager: member_membership,
           week_number: 1,
           season_year: 2025,
           status: :audio_complete)
  end

  let!(:question1) { create(:press_conference_question, press_conference: press_conference, order_index: 1, question_text: "How do you feel about the win?") }
  let!(:question2) { create(:press_conference_question, press_conference: press_conference, order_index: 2, question_text: "What's your strategy going forward?") }
  let!(:question3) { create(:press_conference_question, press_conference: press_conference, order_index: 3, question_text: "Any injuries to report?") }
  
  let!(:response1) { create(:press_conference_response, press_conference_question: question1, response_text: "It feels great to get the win.") }
  let!(:response2) { create(:press_conference_response, press_conference_question: question2, response_text: "We'll keep playing our game.") }
  let!(:response3) { create(:press_conference_response, press_conference_question: question3, response_text: "Everyone is healthy.") }

  before do
    # Attach dummy audio files to simulate a complete press conference
    [question1, question2, question3].each_with_index do |question, i|
      question.question_audio.attach(
        io: StringIO.new("fake question audio #{i}"),
        filename: "question_#{i + 1}.mp3",
        content_type: "audio/mpeg"
      )
    end
    
    [response1, response2, response3].each_with_index do |response, i|
      response.response_audio.attach(
        io: StringIO.new("fake response audio #{i}"),
        filename: "response_#{i + 1}.mp3",
        content_type: "audio/mpeg"
      )
    end
    
    press_conference.final_audio.attach(
      io: StringIO.new("fake final audio"),
      filename: "final_audio.mp3",
      content_type: "audio/mpeg"
    )
  end

  scenario "Owner can delete a press conference and all associated data" do
    # Sign in as the owner
    login_as owner, scope: :user
    
    # Navigate to the press conference show page
    visit league_press_conference_path(league.id, press_conference.id)
    
    # Verify the page loads with expected content
    expect(page).to have_content("Week #{press_conference.week_number} Press Conference")
    expect(page).to have_content("How do you feel about the win?")
    expect(page).to have_content("It feels great to get the win.")
    
    # Verify delete button is visible for owner
    expect(page).to have_link("🗑️ Delete")
    
    # Count initial records
    initial_pc_count = PressConference.count
    initial_question_count = PressConferenceQuestion.count
    initial_response_count = PressConferenceResponse.count
    initial_attachment_count = ActiveStorage::Attachment.count
    
    # Click the delete button and handle the confirmation
    accept_confirm("Are you sure you want to delete this press conference? This will permanently remove all questions, responses, and audio files. This action cannot be undone.") do
      click_link "🗑️ Delete"
    end
    
    # Should redirect to dashboard with success message
    expect(page).to have_current_path(dashboard_league_path(league.id))
    expect(page).to have_content("Press conference and all associated files deleted successfully")
    
    # Verify records were deleted
    expect(PressConference.count).to eq(initial_pc_count - 1)
    expect(PressConferenceQuestion.count).to eq(initial_question_count - 3)
    expect(PressConferenceResponse.count).to eq(initial_response_count - 3)
    expect(ActiveStorage::Attachment.count).to eq(initial_attachment_count - 7)
    
    # Verify the press conference no longer exists
    expect(PressConference.find_by(id: press_conference.id)).to be_nil
  end

  scenario "Non-owner cannot see delete button" do
    # Sign in as a regular member
    login_as member, scope: :user
    
    # Navigate to the press conference show page
    visit league_press_conference_path(league.id, press_conference.id)
    
    # Verify the page loads
    expect(page).to have_content("Week #{press_conference.week_number} Press Conference")
    
    # Verify delete button is NOT visible for non-owner
    expect(page).not_to have_link("🗑️ Delete")
  end

  scenario "Delete removes press conference from dashboard list" do
    # Create another press conference that won't be deleted
    other_pc = create(:press_conference, 
                     league: league, 
                     target_manager: owner_membership,
                     week_number: 2,
                     season_year: 2025,
                     status: :draft)
    
    # Sign in as owner
    login_as owner, scope: :user
    
    # Visit dashboard and verify both conferences are listed
    visit dashboard_league_path(league.id)
    expect(page).to have_content("Week 1")
    expect(page).to have_content("Week 2")
    
    # Navigate to first press conference and delete it
    visit league_press_conference_path(league, press_conference)
    
    accept_confirm do
      click_link "🗑️ Delete"
    end
    
    # Should be back at dashboard
    expect(page).to have_current_path(dashboard_league_path(league.id))
    
    # Verify only the other conference remains
    expect(page).not_to have_content("Week 1")
    expect(page).to have_content("Week 2")
  end
end
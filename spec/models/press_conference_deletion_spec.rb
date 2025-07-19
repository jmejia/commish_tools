require 'rails_helper'

RSpec.describe "Press Conference Deletion Behavior", type: :model do
  let(:owner) { create(:user, first_name: "League", last_name: "Owner") }
  let(:member) { create(:user, first_name: "Team", last_name: "Member") }
  let(:league) { create(:league, owner: owner, name: "Test Fantasy League") }
  let(:owner_membership) { create(:league_membership, league: league, user: owner, role: :owner, team_name: "Owner Team") }
  let(:member_membership) { create(:league_membership, league: league, user: member, role: :manager, team_name: "Member Team") }
  
  let!(:press_conference) do
    create(:press_conference, 
           league: league, 
           target_manager: member_membership,
           week_number: 1,
           season_year: 2025,
           status: :audio_complete)
  end

  let!(:question1) { create(:press_conference_question, press_conference: press_conference, order_index: 1) }
  let!(:question2) { create(:press_conference_question, press_conference: press_conference, order_index: 2) }
  let!(:question3) { create(:press_conference_question, press_conference: press_conference, order_index: 3) }
  
  let!(:response1) { create(:press_conference_response, press_conference_question: question1) }
  let!(:response2) { create(:press_conference_response, press_conference_question: question2) }
  let!(:response3) { create(:press_conference_response, press_conference_question: question3) }

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

  describe "cascade deletion behavior" do
    it "deletes all associated questions, responses, and attachments when press conference is destroyed" do
      # Verify initial state
      expect(PressConference.count).to eq(1)
      expect(PressConferenceQuestion.count).to eq(3)
      expect(PressConferenceResponse.count).to eq(3)
      expect(ActiveStorage::Attachment.count).to eq(7) # 3 questions + 3 responses + 1 final

      # Destroy the press conference
      press_conference.destroy!

      # Verify complete deletion from database
      expect(PressConference.count).to eq(0)
      expect(PressConferenceQuestion.count).to eq(0)
      expect(PressConferenceResponse.count).to eq(0)
      expect(ActiveStorage::Attachment.count).to eq(0)
    end

    it "enqueues background jobs to purge blob files when destroyed" do
      # Verify that Active Storage purge jobs are enqueued
      expect {
        press_conference.destroy!
      }.to have_enqueued_job(ActiveStorage::PurgeJob).exactly(7).times
    end

    it "handles deletion gracefully even when some audio files are missing" do
      # Remove some audio files to test partial deletion
      question1.question_audio.purge
      response2.response_audio.purge
      
      # Should still delete successfully
      expect {
        press_conference.destroy!
      }.to change(PressConference, :count).by(-1)
       .and change(PressConferenceQuestion, :count).by(-3)
       .and change(PressConferenceResponse, :count).by(-3)
    end

    it "properly cleans up when press conference has no audio files" do
      # Create a minimal press conference without audio
      simple_pc = create(:press_conference, 
                        league: league, 
                        target_manager: member_membership,
                        week_number: 2,
                        status: :draft)
      simple_question = create(:press_conference_question, press_conference: simple_pc, order_index: 1)
      
      expect {
        simple_pc.destroy!
      }.to change(PressConference, :count).by(-1)
       .and change(PressConferenceQuestion, :count).by(-1)
    end

    it "maintains referential integrity during deletion" do
      question_ids = [question1.id, question2.id, question3.id]
      response_ids = [response1.id, response2.id, response3.id]
      
      press_conference.destroy!
      
      # Verify no orphaned records remain
      expect(PressConferenceQuestion.where(id: question_ids)).to be_empty
      expect(PressConferenceResponse.where(id: response_ids)).to be_empty
    end
  end

  describe "Active Storage file cleanup" do
    it "removes all associated blob files when press conference is destroyed" do
      # Get the blob IDs before deletion
      blob_ids = []
      
      press_conference.press_conference_questions.each do |question|
        blob_ids << question.question_audio.blob.id if question.question_audio.attached?
        if question.press_conference_response&.response_audio&.attached?
          blob_ids << question.press_conference_response.response_audio.blob.id
        end
      end
      
      blob_ids << press_conference.final_audio.blob.id if press_conference.final_audio.attached?
      
      expect(blob_ids.count).to eq(7)
      
      # Destroy the press conference
      press_conference.destroy!
      
      # Verify the specific blobs are scheduled for deletion
      blob_ids.each do |blob_id|
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to include(
          hash_including(
            job: ActiveStorage::PurgeJob,
            args: [hash_including("_aj_globalid" => "gid://commish-tools/ActiveStorage::Blob/#{blob_id}")]
          )
        )
      end
    end
  end
end
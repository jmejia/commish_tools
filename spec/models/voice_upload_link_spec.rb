require 'rails_helper'

RSpec.describe VoiceUploadLink, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      voice_clone = create(:voice_clone)
      link = build(:voice_upload_link, voice_clone: voice_clone)
      expect(link).to be_valid
    end

    it "is invalid without a voice_clone" do
      link = build(:voice_upload_link, voice_clone: nil)
      expect(link).not_to be_valid
    end

    it "has a unique public_token" do
      link1 = create(:voice_upload_link)
      link2 = build(:voice_upload_link, public_token: link1.public_token)
      expect(link2).not_to be_valid
    end
  end

  describe "callbacks" do
    it "generates a public_token before creation" do
      link = build(:voice_upload_link, public_token: nil)
      link.valid?
      expect(link.public_token).not_to be_blank
    end
  end
end

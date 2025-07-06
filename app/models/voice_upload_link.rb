class VoiceUploadLink < ApplicationRecord
  belongs_to :voice_clone

  before_validation :generate_public_token, on: :create

  validates :public_token, presence: true, uniqueness: true
  validates :voice_clone_id, presence: true

  private

  def generate_public_token
    self.public_token = SecureRandom.uuid if public_token.blank?
  end
end

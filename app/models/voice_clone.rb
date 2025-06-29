# Represents an AI voice clone for a league member, used to generate
# personalized press conference responses with their unique voice.
class VoiceClone < ApplicationRecord
  belongs_to :league_membership

  has_one :user, through: :league_membership
  has_one :league, through: :league_membership

  enum :status, {
    pending: 0,
    processing: 1,
    ready: 2,
    failed: 3,
  }

  validates :status, presence: true
  validates :upload_token, presence: true, uniqueness: true
  validates :league_membership_id, uniqueness: true

  scope :ready_for_use, -> { where(status: :ready) }
  scope :for_league, ->(league) { joins(:league_membership).where(league_memberships: { league: league }) }

  before_create :generate_upload_token

  def ready_for_playht?
    ready? && playht_voice_id.present?
  end

  def audio_file_name
    return nil unless original_audio_url.present?

    File.basename(original_audio_url)
  end

  def user_display_name
    league_membership.display_name
  end

  private

  def generate_upload_token
    self.upload_token = SecureRandom.urlsafe_base64(32)
  end
end

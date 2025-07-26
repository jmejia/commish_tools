# Represents an AI voice clone for a league member, used to generate
# personalized press conference responses with their unique voice.
class VoiceClone < ApplicationRecord
  belongs_to :league_membership

  has_one :user, through: :league_membership
  has_one :league, through: :league_membership
  has_many :voice_upload_links, dependent: :destroy
  has_one_attached :audio_file

  enum :status, {
    pending: 0,
    processing: 1,
    ready: 2,
    failed: 3,
  }

  validates :status, presence: true
  validates :upload_token, presence: true, uniqueness: true
  validates :league_membership_id, uniqueness: true

  validate :audio_file_content_type, if: -> { audio_file.attached? }
  validate :audio_file_size, if: -> { audio_file.attached? }

  before_validation :set_defaults, on: :create

  def ready_for_playht?
    ready? && playht_voice_id.present?
  end

  def audio_file_name
    if audio_file.attached?
      audio_file.filename.to_s
    elsif original_audio_url.present?
      File.basename(original_audio_url)
    else
      nil
    end
  end

  def user_display_name
    league_membership.display_name
  end

  private

  def set_defaults
    self.status ||= :pending
    self.upload_token ||= SecureRandom.urlsafe_base64(32)
  end

  def audio_file_content_type
    allowed_types = ['audio/mpeg', 'audio/wav', 'audio/mp4', 'audio/webm', 'audio/m4a']
    unless allowed_types.include?(audio_file.content_type)
      errors.add(:audio_file, "must be an audio file (#{allowed_types.join(', ')})")
    end
  end

  def audio_file_size
    if audio_file.byte_size < 1.megabyte
      errors.add(:audio_file, 'must be at least 1MB')
    elsif audio_file.byte_size > 50.megabytes
      errors.add(:audio_file, 'must be less than 50MB')
    end
  end

  scope :ready_for_use, -> { where(status: :ready) }
  scope :for_league, ->(league) { joins(:league_membership).where(league_memberships: { league: league }) }
end

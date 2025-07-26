# Represents a scheduling poll for league events (draft, playoffs, etc.)
# Allows commissioners to create polls with multiple time slots and collect availability from members
class SchedulingPoll < ApplicationRecord
  belongs_to :league
  belongs_to :created_by, class_name: 'User'

  has_many :event_time_slots, -> { order(:order_index, :starts_at) }, dependent: :destroy
  has_many :scheduling_responses, dependent: :destroy

  enum :status, { active: 0, closed: 1, cancelled: 2 }

  # For now we focus on draft, but can be extended to other event types
  EVENT_TYPES = {
    draft: 'Draft'
  }.freeze

  before_create :generate_public_token

  validates :title, presence: true, length: { maximum: 100 }
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES.keys.map(&:to_s) }

  accepts_nested_attributes_for :event_time_slots, allow_destroy: true

  scope :drafts, -> { where(event_type: 'draft') }
  scope :active_for_league, ->(league) { where(league: league, status: :active) }

  def response_count
    scheduling_responses.count
  end

  def response_rate
    return 0 if league.members_count.zero?

    (response_count.to_f / league.members_count * 100).round
  end

  def optimal_slots(limit: 3)
    # Get all time slots with their availability counts
    slots_with_counts = event_time_slots.includes(:slot_availabilities).map do |slot|
      availabilities = slot.slot_availabilities.group(:availability).count
      [slot, availabilities[2] || 0, availabilities[1] || 0] # [slot, available_count, maybe_count]
    end
    
    # Sort by available count first, then maybe count
    sorted_slots = slots_with_counts.sort_by { |_, available, maybe| [-available, -maybe] }
    
    # Return just the slots, limited by the requested amount
    sorted_slots.first(limit).map(&:first)
  end

  def default_duration_minutes
    case event_type
    when 'draft' then 180
    else 60
    end
  end

  def close!
    update!(status: :closed)
  end

  def reopen!
    update!(status: :active)
  end

  def public_url
    # In development/test, use a default host if not configured
    host = Rails.application.config.action_mailer.default_url_options&.fetch(:host, 'localhost:3000') || 'localhost:3000'
    Rails.application.routes.url_helpers.public_scheduling_url(
      token: public_token,
      host: host
    )
  end

  private

  def generate_public_token
    loop do
      self.public_token = SecureRandom.urlsafe_base64(8)
      break unless self.class.exists?(public_token: public_token)
    end
  end
end
# Represents a scheduling poll for league events (draft, playoffs, etc.)
# Allows commissioners to create polls with multiple time slots and collect availability from members
class SchedulingPoll < ApplicationRecord
  # Result object for poll creation operations
  CreationResult = Struct.new(:success?, :poll, :message, :error, keyword_init: true)

  belongs_to :league
  belongs_to :created_by, class_name: 'User'

  has_many :event_time_slots, -> { order(:order_index, :starts_at) }, dependent: :destroy
  has_many :scheduling_responses, dependent: :destroy

  enum :status, { active: 0, closed: 1, cancelled: 2 }

  # Extensible event types configuration - can be extended via Rails configuration
  EVENT_TYPES = begin
    Rails.application.config.try(:scheduling_event_types) || {
      draft: 'Draft',
      playoffs: 'Playoffs',
      championship: 'Championship',
      meeting: 'League Meeting',
    }
                rescue StandardError
                  {
                    draft: 'Draft',
                    playoffs: 'Playoffs',
                    championship: 'Championship',
                    meeting: 'League Meeting',
                  }
  end.freeze

  before_create :generate_public_token

  validates :title, presence: true, length: { maximum: 100 }
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES.keys.map(&:to_s) }

  accepts_nested_attributes_for :event_time_slots, allow_destroy: true

  scope :drafts, -> { where(event_type: 'draft') }
  scope :active_for_league, ->(league) { where(league: league, status: :active) }
  scope :with_responses, -> { includes(scheduling_responses: { slot_availabilities: :event_time_slot }) }
  scope :with_time_slots, -> { includes(:event_time_slots) }
  scope :with_full_data, -> {
    includes(:event_time_slots, scheduling_responses: { slot_availabilities: :event_time_slot })
  }

  # Domain method to create a poll with proper validation and error handling
  # Replaces PollCreator service object
  def self.create_for_league(league:, created_by:, params:)
    poll = league.scheduling_polls.build(params)
    poll.created_by = created_by

    if poll.save
      CreationResult.new(
        success?: true,
        poll: poll,
        message: 'Poll created successfully.'
      )
    else
      CreationResult.new(
        success?: false,
        poll: poll,
        error: poll.errors.full_messages.to_sentence
      )
    end
  end

  def response_count
    scheduling_responses.count
  end

  def response_rate
    return 0 if league.members_count.zero?

    (response_count.to_f / league.members_count * 100).round
  end

  def optimal_slots(limit: 3)
    # Use a single optimized query to avoid N+1 issues
    # Select all columns from event_time_slots and order by availability counts
    # Convert to array to ensure proper behavior with .count
    event_time_slots.
      select("event_time_slots.*").
      joins("LEFT JOIN slot_availabilities ON slot_availabilities.event_time_slot_id = event_time_slots.id").
      group("event_time_slots.id").
      order(
        Arel.sql("SUM(CASE WHEN slot_availabilities.availability = 2 THEN 1 ELSE 0 END) DESC"),
        Arel.sql("SUM(CASE WHEN slot_availabilities.availability = 1 THEN 1 ELSE 0 END) DESC"),
        :starts_at
      ).
      limit(limit).
      to_a
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
    host = Rails.application.config.action_mailer.default_url_options&.fetch(:host,
'localhost:3000') || 'localhost:3000'
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

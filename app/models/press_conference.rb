# Represents a weekly press conference for a fantasy football league.
# Contains questions and responses from league members.
class PressConference < ApplicationRecord
  belongs_to :league
  belongs_to :target_manager, class_name: 'LeagueMembership'

  has_many :press_conference_questions, dependent: :destroy
  has_many :press_conference_responses, through: :press_conference_questions
  has_one_attached :final_audio

  enum :status, {
    draft: 0,
    generating: 1,
    ready: 2,
    archived: 3,
    audio_complete: 4,
    audio_failed: 5,
  }

  validates :week_number, presence: true,
                          numericality: { greater_than: 0, less_than_or_equal_to: 18 }
  validates :season_year, presence: true,
                          numericality: { greater_than: 2000, less_than_or_equal_to: -> { Date.current.year + 1 } }
  validates :status, presence: true
  validates :week_number, uniqueness: {
    scope: [:league_id, :season_year],
    message: 'Press conference already exists for this week',
  }

  scope :current_season, -> { where(season_year: Date.current.year) }
  scope :for_week, ->(week) { where(week_number: week) }
  scope :completed, -> { where(status: [:ready, :archived]) }

  def ordered_questions
    press_conference_questions.order(:order_index)
  end

  def complete_audio_url
    return nil unless ready?

    context_data&.dig('complete_audio_url')
  end

  def total_duration
    return 0 unless context_data&.dig('total_duration')

    context_data['total_duration']
  end

  def target_manager_display_name
    target_manager.display_name
  end

  def questions_count
    press_conference_questions.count
  end

  def responses_count
    press_conference_responses.count
  end

  def deletion_details
    {
      questions_count: press_conference_questions.count,
      responses_count: press_conference_responses.count,
      has_final_audio: final_audio.attached?,
      question_audio_count: press_conference_questions.joins(:question_audio_attachment).count,
      response_audio_count: press_conference_responses.joins(:response_audio_attachment).count
    }
  end

  def log_deletion_details
    details = deletion_details
    Rails.logger.info "Deleting press conference #{id}: " \
                      "#{details[:questions_count]} questions, #{details[:responses_count]} responses, " \
                      "#{details[:question_audio_count]} question audio files, " \
                      "#{details[:response_audio_count]} response audio files, " \
                      "final audio: #{details[:has_final_audio]}"
  end
end

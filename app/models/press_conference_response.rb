class PressConferenceResponse < ApplicationRecord
  belongs_to :press_conference_question

  has_one :press_conference, through: :press_conference_question

  validates :response_text, presence: true, length: { maximum: 2000 }
  validates :generation_prompt, presence: true

  scope :with_audio, -> { where.not(response_audio_url: nil) }

  def has_audio?
    response_audio_url.present?
  end

  def word_count
    response_text.split.size
  end

  def estimated_duration_seconds
    # Rough estimate: 150 words per minute for speech
    (word_count / 150.0) * 60
  end

  def question_text
    press_conference_question.question_text
  end
end

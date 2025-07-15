# Represents an individual question within a press conference.
# Questions are ordered and can have multiple responses from league members.
class PressConferenceQuestion < ApplicationRecord
  belongs_to :press_conference

  has_one :press_conference_response, dependent: :destroy
  has_one_attached :question_audio

  validates :question_text, presence: true, length: { maximum: 500 }
  validates :order_index, presence: true,
                          numericality: { greater_than_or_equal_to: 0 }
  validates :order_index, uniqueness: { scope: :press_conference_id }

  scope :ordered, -> { order(:order_index) }
  scope :with_audio, -> { where.not(question_audio_url: nil) }

  def has_audio?
    question_audio_url.present?
  end

  def has_response?
    press_conference_response.present?
  end

  def response_text
    press_conference_response&.response_text
  end

  def response_audio_url
    press_conference_response&.response_audio_url
  end
end

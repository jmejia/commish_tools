class SleeperConnectionRequest < ApplicationRecord
  belongs_to :user
  belongs_to :reviewed_by, class_name: 'User', optional: true

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
  }

  validates :sleeper_username, presence: true
  validates :sleeper_id, presence: true
  validates :requested_at, presence: true

  scope :recent, -> { order(requested_at: :desc) }
  scope :needs_review, -> { pending.order(requested_at: :asc) }

  def approve!(reviewed_by_user)
    transaction do
      update!(
        status: :approved,
        reviewed_at: Time.current,
        reviewed_by: reviewed_by_user
      )

      # Update the user's sleeper connection
      user.update!(
        sleeper_username: sleeper_username,
        sleeper_id: sleeper_id
      )
    end
  end

  def reject!(reviewed_by_user, reason = nil)
    update!(
      status: :rejected,
      reviewed_at: Time.current,
      reviewed_by: reviewed_by_user,
      rejection_reason: reason
    )
  end
end

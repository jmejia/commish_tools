class SuperAdmin < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true

  scope :active, -> { joins(:user).where(users: { deleted_at: nil }) }
end

class LeagueMembership < ApplicationRecord
  belongs_to :league
  belongs_to :user

  has_many :voice_clones, dependent: :destroy

  enum :role, {
    manager: 0,
    owner: 1,
  }

  validates :sleeper_user_id, presence: true
  validates :team_name, presence: true, length: { maximum: 50 }
  validates :role, presence: true
  validates :user_id, uniqueness: {
    scope: :league_id,
    message: 'User already belongs to this league',
  }

  scope :owners, -> { where(role: :owner) }
  scope :managers, -> { where(role: :manager) }
  scope :for_league, ->(league) { where(league: league) }

  def display_name
    team_name.presence || user.display_name
  end

  def owner?
    role == 'owner'
  end

  def manager?
    role == 'manager'
  end
end

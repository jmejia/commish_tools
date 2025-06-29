# Represents a fantasy football league, which can be imported from Sleeper
# or created manually. Contains members and associated press conferences.
class League < ApplicationRecord
  belongs_to :owner, class_name: 'User'

  has_many :league_memberships, dependent: :destroy
  has_many :users, through: :league_memberships
  has_many :press_conferences, dependent: :destroy
  has_many :voice_clones, through: :league_memberships

  validates :sleeper_league_id, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 100 }
  validates :season_year, presence: true,
                          numericality: { greater_than: 2000, less_than_or_equal_to: -> { Date.current.year + 1 } }

  scope :current_season, -> { where(season_year: Date.current.year) }
  scope :for_owner, ->(user) { where(owner: user) }

  def current_season?
    season_year == Date.current.year
  end

  def members_count
    league_memberships.count
  end
end

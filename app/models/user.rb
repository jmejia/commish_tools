class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, {
    team_manager: 0,
    league_owner: 1,
  }

  has_many :owned_leagues, class_name: 'League', foreign_key: 'owner_id', dependent: :destroy
  has_many :league_memberships, dependent: :destroy
  has_many :leagues, through: :league_memberships
  has_many :voice_clones, through: :league_memberships

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :role, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    full_name.strip.presence || email
  end
end

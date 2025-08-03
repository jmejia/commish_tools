# Represents a user in the fantasy football commissioner application.
# Handles authentication, Sleeper account integration, and league management.
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: [:google_oauth2]

  enum :role, {
    team_manager: 0,
    league_owner: 1,
  }

  has_many :owned_leagues, class_name: 'League', foreign_key: 'owner_id', dependent: :destroy
  has_many :league_memberships, dependent: :destroy
  has_many :leagues, through: :league_memberships
  has_many :voice_clones, through: :league_memberships
  has_many :draft_grades, dependent: :destroy
  has_one :super_admin, dependent: :destroy
  has_many :sleeper_connection_requests, dependent: :destroy

  # Set default role before validation
  before_validation :set_default_role, on: :create

  validates :first_name, length: { maximum: 50 }, allow_blank: true
  validates :last_name, length: { maximum: 50 }, allow_blank: true
  validates :role, presence: true
  validates :sleeper_username, uniqueness: true, allow_blank: true
  validates :sleeper_id, uniqueness: true, allow_blank: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    full_name.strip.presence || email
  end

  def super_admin?
    super_admin.present?
  end

  def sleeper_connected?
    sleeper_id.present?
  end

  def connect_sleeper_account(username)
    # Check if there's already a pending request
    return false if sleeper_connection_pending?

    client = SleeperFF.new
    user_data = client.user(username)

    if user_data
      # Create a pending connection request instead of immediately connecting
      sleeper_connection_requests.create!(
        sleeper_username: user_data.username,
        sleeper_id: user_data.user_id,
        requested_at: Time.current
      )

      # Send notification to super admins
      SuperAdminMailer.sleeper_connection_requested(self, user_data.username).deliver_later unless Rails.env.test?

      true
    else
      false
    end
  rescue StandardError => exception
    Rails.logger.error "Failed to request Sleeper account connection for user #{id}: #{exception.message}"
    false
  end

  def fetch_sleeper_leagues(season = Date.current.year)
    return [] unless sleeper_connected?

    client = SleeperFF.new
    client.user_leagues(sleeper_id, season)
  rescue StandardError => exception
    Rails.logger.error "Failed to fetch Sleeper leagues for user #{id}: #{exception.message}"
    []
  end

  def self.from_omniauth(auth)
    auth_info = auth.info

    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth_info.email
      user.password = Devise.friendly_token[0, 20]
      user.first_name = auth_info.first_name
      user.last_name = auth_info.last_name
      user.role = :team_manager
    end
  end

  def sleeper_connection_pending?
    sleeper_connection_requests.pending.exists?
  end

  def latest_sleeper_request
    sleeper_connection_requests.recent.first
  end

  private

  def set_default_role
    self.role ||= :team_manager
  end
end

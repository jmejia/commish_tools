require 'ostruct'

class LeagueCreation
  attr_reader :user, :league_params

  def initialize(user:, league_params:)
    @user = user
    @league_params = league_params
  end

  def create
    Rails.logger.info "User #{user.id} attempting to create league with params: #{league_params}"

    league = League.new(league_params.merge(owner_id: user.id))

    create_league_and_membership(league)
  end

  private

  def create_league_and_membership(league)
    ActiveRecord::Base.transaction do
      if league.save
        league.league_memberships.create!(
          user: user,
          role: :owner
        )
        Rails.logger.info "League #{league.id} created successfully by user #{user.id}"
        success(league: league, message: "League was successfully created.")
      else
        Rails.logger.warn "League creation failed for user #{user.id}: #{league.errors.full_messages}"
        failure(league: league, errors: league.errors)
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "League creation failed for user #{user.id}: #{e.message}"
    failure(league: league, errors: league.errors)
  end

  def success(league:, message:)
    OpenStruct.new(
      success?: true,
      league: league,
      message: message,
      errors: nil
    )
  end

  def failure(league:, errors:)
    OpenStruct.new(
      success?: false,
      league: league,
      message: nil,
      errors: errors
    )
  end
end

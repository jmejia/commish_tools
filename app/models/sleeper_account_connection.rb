require 'ostruct'

class SleeperAccountConnection
  attr_reader :user, :username

  def initialize(user:, username:)
    @user = user
    @username = username
  end

  def connect
    Rails.logger.info "User #{user.id} attempting to connect Sleeper account with username: #{username}"

    # Check if user already has a pending request
    if user.sleeper_connection_pending?
      Rails.logger.info "User #{user.id} already has a pending Sleeper connection request"
      return failure("You already have a pending Sleeper connection request. Please wait for admin approval.")
    end

    if user.connect_sleeper_account(username)
      Rails.logger.info "Sleeper connection request created successfully for user #{user.id}"
      success("Sleeper connection request submitted! You'll receive an email once an admin approves your request.")
    else
      Rails.logger.warn "Failed to create Sleeper connection request for user #{user.id}"
      failure("Failed to connect Sleeper account. Please check your username and try again.")
    end
  end

  private

  def success(message)
    OpenStruct.new(
      success?: true,
      message: message,
      error: nil
    )
  end

  def failure(error_message)
    OpenStruct.new(
      success?: false,
      message: nil,
      error: error_message
    )
  end
end

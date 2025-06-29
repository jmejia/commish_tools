class SleeperAccountConnection
  attr_reader :user, :username

  def initialize(user:, username:)
    @user = user
    @username = username
  end

  def connect
    Rails.logger.info "User #{user.id} attempting to connect Sleeper account with username: #{username}"

    if user.connect_sleeper_account(username)
      Rails.logger.info "Sleeper account connected successfully for user #{user.id}"
      success("Sleeper account connected successfully!")
    else
      Rails.logger.warn "Failed to connect Sleeper account for user #{user.id}"
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

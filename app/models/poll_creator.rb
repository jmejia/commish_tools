# Service object for creating scheduling polls
class PollCreator
  Result = Struct.new(:success?, :poll, :message, :error, keyword_init: true)

  def initialize(league:, user:, params:)
    @league = league
    @user = user
    @params = params
  end

  def create
    poll = @league.scheduling_polls.build(@params)
    poll.created_by = @user

    if poll.save
      Result.new(
        success?: true,
        poll: poll,
        message: 'Poll created successfully.'
      )
    else
      Result.new(
        success?: false,
        poll: poll,
        error: poll.errors.full_messages.to_sentence
      )
    end
  end
end
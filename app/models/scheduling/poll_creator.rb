# PORO for creating scheduling polls
# Extracted from SchedulingPoll.create_for_league
module Scheduling
  class PollCreator
    # Result object for poll creation operations
    CreationResult = Struct.new(:success?, :poll, :message, :error, keyword_init: true)

    def initialize(league:, created_by:)
      @league = league
      @created_by = created_by
    end

    def create(params)
      poll = league.scheduling_polls.build(params)
      poll.created_by = created_by

      if poll.save
        CreationResult.new(
          success?: true,
          poll: poll,
          message: 'Poll created successfully.'
        )
      else
        CreationResult.new(
          success?: false,
          poll: poll,
          error: poll.errors.full_messages.to_sentence
        )
      end
    end

    private

    attr_reader :league, :created_by
  end
end

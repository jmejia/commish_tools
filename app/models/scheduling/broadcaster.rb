# PORO for broadcasting scheduling poll updates
# Extracted from SchedulingPoll#broadcast_updates
module Scheduling
  class Broadcaster
    def initialize(poll)
      @poll = poll
    end

    def broadcast_updates
      # Reload with all associations to ensure fresh data
      poll_with_data = SchedulingPoll.includes(
        :league,
        :event_time_slots,
        scheduling_responses: { slot_availabilities: :event_time_slot }
      ).find(poll.id)

      # Broadcast the entire results section as one update
      Turbo::StreamsChannel.broadcast_replace_to(
        "scheduling_poll_#{poll.id}",
        target: "poll-results",
        partial: "scheduling/polls/results",
        locals: {
          poll: poll_with_data,
          responses: poll_with_data.scheduling_responses,
        }
      )
    end

    private

    attr_reader :poll
  end
end

# Handles broadcasting poll updates via Turbo Streams
# Encapsulates poll reloading and Turbo broadcast logic
class PollBroadcaster
  def initialize(response)
    @response = response
  end

  def broadcast_updates
    poll = reload_poll_with_associations

    Turbo::StreamsChannel.broadcast_replace_to(
      "scheduling_poll_#{poll.id}",
      target: "poll-results",
      partial: "scheduling_polls/results",
      locals: {
        poll: poll,
        responses: poll.scheduling_responses,
      }
    )
  end

  private

  attr_reader :response

  def reload_poll_with_associations
    poll = response.scheduling_poll

    # Reload poll with all associations to ensure fresh data
    SchedulingPoll.includes(
      :league,
      :event_time_slots,
      scheduling_responses: { slot_availabilities: :event_time_slot }
    ).find(poll.id)
  end
end

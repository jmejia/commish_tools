# PORO for exporting scheduling poll data to CSV
# Extracted from SchedulingPoll#to_csv
module Scheduling
  class CsvExporter
    def initialize(poll)
      @poll = poll
    end

    def export
      require 'csv'

      CSV.generate(headers: true) do |csv|
        # Header row
        headers = ['Member Name'] + poll.event_time_slots.map(&:display_label)
        csv << headers

        # Response rows
        poll.scheduling_responses.includes(slot_availabilities: :event_time_slot).each do |response|
          row = [response.respondent_name]

          poll.event_time_slots.each do |slot|
            availability = response.slot_availabilities.find { |sa| sa.event_time_slot_id == slot.id }
            row << case availability&.availability
                   when 'available_ideal' then 'Available and works well'
                   when 'available_not_ideal' then 'Available but not ideal'
                   else 'Not available'
                   end
          end

          csv << row
        end

        # Add non-respondents
        poll.non_respondents.each do |membership|
          row = [membership.user.display_name] + (['No Response'] * poll.event_time_slots.count)
          csv << row
        end
      end
    end

    private

    attr_reader :poll
  end
end
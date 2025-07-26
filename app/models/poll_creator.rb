require 'ostruct'

# Domain object responsible for creating scheduling polls with time slots
# Follows the pattern established in the codebase for business logic
class PollCreator
  attr_reader :league, :user, :params

  def initialize(league:, user:, params:)
    @league = league
    @user = user
    @params = params
  end

  def create
    Rails.logger.info "Creating scheduling poll for league #{league.id} by user #{user.id}"

    return failure("You must be the league owner to create polls.") unless league.owner == user

    ActiveRecord::Base.transaction do
      poll = build_poll
      
      if poll.save
        Rails.logger.info "Scheduling poll #{poll.id} created successfully"
        success(poll: poll, message: "Scheduling poll created successfully!")
      else
        Rails.logger.error "Failed to create scheduling poll: #{poll.errors.full_messages.join(', ')}"
        failure(poll.errors.full_messages.join(', '))
      end
    end
  rescue StandardError => exception
    Rails.logger.error "Error creating scheduling poll: #{exception.message}"
    failure("An error occurred while creating the poll.")
  end

  private

  def build_poll
    poll = league.scheduling_polls.build(
      created_by: user,
      event_type: params[:event_type] || 'draft',
      title: params[:title],
      description: params[:description],
      status: :active
    )

    # Add time slots if provided
    if params[:event_time_slots_attributes].present?
      poll.event_time_slots_attributes = params[:event_time_slots_attributes]
    end

    poll
  end

  def success(poll:, message:)
    OpenStruct.new(
      success?: true,
      poll: poll,
      message: message,
      error: nil
    )
  end

  def failure(error_message)
    OpenStruct.new(
      success?: false,
      poll: nil,
      message: nil,
      error: error_message
    )
  end
end
# frozen_string_literal: true

module Admin
  class SleeperConnectionRequestsController < BaseController
    before_action :set_request, only: [:show, :approve, :reject]

    def index
      @pending_requests = SleeperConnectionRequest.includes(:user).needs_review
      @recent_requests = SleeperConnectionRequest.includes(:user, :reviewed_by).recent.limit(20)
    end

    def show
      # Individual request details
    end

    def approve
      if @sleeper_request.approve!(current_user)
        redirect_to admin_sleeper_connection_requests_path,
                    notice: "Approved Sleeper connection for #{@sleeper_request.user.display_name}."
      else
        redirect_to admin_sleeper_connection_requests_path,
                    alert: "Failed to approve Sleeper connection."
      end
    end

    def reject
      reason = params[:rejection_reason]

      if @sleeper_request.reject!(current_user, reason)
        redirect_to admin_sleeper_connection_requests_path,
                    notice: "Rejected Sleeper connection for #{@sleeper_request.user.display_name}."
      else
        redirect_to admin_sleeper_connection_requests_path,
                    alert: "Failed to reject Sleeper connection."
      end
    end

    private

    def set_request
      @sleeper_request = SleeperConnectionRequest.find(params[:id])
    end
  end
end

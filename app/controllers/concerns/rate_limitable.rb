# frozen_string_literal: true

# Concern for adding rate limiting functionality to controllers
# Protects against abuse while allowing legitimate usage
module RateLimitable
  extend ActiveSupport::Concern

  # Rate limiting configuration per action type
  RATE_LIMITS = {
    public_response: { limit: 10, period: 1.hour },
    poll_creation: { limit: 5, period: 1.hour },
    poll_access: { limit: 60, period: 1.hour },
  }.freeze

  included do
    # Simple in-memory rate limiting using Rails cache
    # In production, consider using Redis or database-backed solution
    def check_rate_limit(action_type, identifier = request.remote_ip)
      # Skip rate limiting in test environment
      return true if Rails.env.test?

      config = RATE_LIMITS[action_type]
      return true unless config

      cache_key = "rate_limit:#{action_type}:#{identifier}"
      current_count = Rails.cache.read(cache_key) || 0

      if current_count >= config[:limit]
        render_rate_limit_exceeded
        return false
      end

      # Increment counter with expiration
      Rails.cache.write(cache_key, current_count + 1, expires_in: config[:period])
      true
    end

    private

    def render_rate_limit_exceeded
      respond_to do |format|
        format.html do
          render plain: 'Rate limit exceeded. Please try again later.',
                 status: :too_many_requests
        end
        format.json do
          render json: { error: 'Rate limit exceeded' },
                 status: :too_many_requests
        end
      end
    end
  end
end

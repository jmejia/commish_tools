# frozen_string_literal: true

# Concern for adding spam protection functionality to controllers
# Uses honeypot fields and other techniques to detect automated submissions
module SpamProtectable
  extend ActiveSupport::Concern

  included do
    # Check for honeypot field submissions (should be empty)
    def check_honeypot(honeypot_field = :email_confirm)
      if params[honeypot_field].present?
        Rails.logger.warn "Honeypot triggered from IP: #{request.remote_ip}, UA: #{request.user_agent}"
        render_spam_detected
        return false
      end
      true
    end

    # Basic spam detection based on submission patterns
    def check_spam_patterns(text_fields = [])
      return true if text_fields.empty?

      text_content = text_fields.map { |field| params[field].to_s }.join(' ')
      
      # Check for common spam indicators
      spam_indicators = [
        /https?:\/\/[^\s]+/i,  # URLs
        /\b(?:viagra|cialis|pharmacy|casino|poker)\b/i,  # Common spam words
        /[A-Z]{10,}/,  # Excessive caps
        /(.)\1{5,}/    # Repeated characters
      ]

      if spam_indicators.any? { |pattern| text_content.match?(pattern) }
        Rails.logger.warn "Spam pattern detected from IP: #{request.remote_ip}"
        render_spam_detected
        return false
      end

      true
    end

    # Time-based submission check (too fast = likely bot)
    def check_submission_timing(form_start_time_param = :form_start_time)
      # Skip timing check in test environment or if no timestamp provided
      return true if Rails.env.test? || !params[form_start_time_param].present?

      begin
        form_start_time = Time.parse(params[form_start_time_param])
        submission_time = Time.current - form_start_time

        # Flag submissions faster than 3 seconds as suspicious
        if submission_time < 3.seconds
          Rails.logger.warn "Fast submission detected from IP: #{request.remote_ip} (#{submission_time}s)"
          render_spam_detected
          return false
        end
      rescue ArgumentError
        # Invalid time format, treat as suspicious in production only
        unless Rails.env.test?
          Rails.logger.warn "Invalid form start time from IP: #{request.remote_ip}"
          render_spam_detected
          return false
        end
      end

      true
    end

    private

    def render_spam_detected
      respond_to do |format|
        format.html do
          render plain: 'Submission rejected. Please try again.', 
                 status: :unprocessable_entity
        end
        format.json do
          render json: { error: 'Submission rejected' }, 
                 status: :unprocessable_entity
        end
      end
    end
  end
end
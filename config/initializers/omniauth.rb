# frozen_string_literal: true

# OmniAuth configuration
OmniAuth.config.logger = Rails.logger

# Allow both GET and POST requests
OmniAuth.config.allowed_request_methods = [:get, :post]

# Disable CSRF protection
OmniAuth.config.request_validation_phase = proc { |env| }

# Silence GET warning
OmniAuth.config.silence_get_warning = true 
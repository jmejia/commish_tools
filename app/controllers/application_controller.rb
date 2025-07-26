# Base controller for all application controllers.
# Provides common authentication and security features.
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?
  
  # Skip host authorization in test environment
  skip_before_action :verify_authenticity_token, if: -> { Rails.env.test? }
end

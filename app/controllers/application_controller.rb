# Base controller for all application controllers.
# Provides common authentication and security features.
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

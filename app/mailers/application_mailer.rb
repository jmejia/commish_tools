# Base mailer class for all email notifications in the application.
# Provides common email configuration and layouts.
class ApplicationMailer < ActionMailer::Base
  default from: "noreply@commishtools.com"
  layout "mailer"
end

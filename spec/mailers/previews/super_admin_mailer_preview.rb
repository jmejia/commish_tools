# Preview all emails at http://localhost:3000/rails/mailers/super_admin_mailer_mailer
class SuperAdminMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/super_admin_mailer_mailer/sleeper_connection_requested
  def sleeper_connection_requested
    SuperAdminMailer.sleeper_connection_requested
  end
end

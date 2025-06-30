class SuperAdminMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.super_admin_mailer.sleeper_connection_requested.subject
  #
  def sleeper_connection_requested(user, sleeper_username)
    @user = user
    @sleeper_username = sleeper_username

    # Send to all super admins
    super_admin_emails = User.joins(:super_admin).pluck(:email)

    mail(
      to: super_admin_emails,
      subject: "New Sleeper Connection Request - #{user.display_name}"
    )
  end
end

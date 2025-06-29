# Handles OAuth authentication callbacks from third-party providers like Google.
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    omniauth_data = request.env['omniauth.auth']
    user = User.from_omniauth(omniauth_data)

    if user.persisted?
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Google') if is_navigational_format?
    else
      session['devise.google_data'] = omniauth_data.except(:extra)
      redirect_to new_user_registration_url, alert: user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: 'Authentication failed. Please try again.'
  end
end

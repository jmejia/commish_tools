module OmniauthHelpers
  def mock_google_oauth_success(user_info = {})
    default_info = {
      email: 'test@example.com',
      first_name: 'John',
      last_name: 'Doe'
    }
    
    auth_hash = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '123456789',
      info: default_info.merge(user_info),
      credentials: {
        token: 'mock_token',
        refresh_token: 'mock_refresh_token'
      }
    })
    
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
    Rails.application.env_config['omniauth.auth'] = auth_hash
  end

  def mock_google_oauth_failure
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
  end

  def reset_omniauth_mocks
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    Rails.application.env_config['omniauth.auth'] = nil
  end
end

RSpec.configure do |config|
  config.include OmniauthHelpers, type: :feature
  config.include OmniauthHelpers, type: :request
  
  config.after(:each, type: :feature) do
    reset_omniauth_mocks
  end
end 
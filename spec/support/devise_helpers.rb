RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller

  config.before(:each, type: :feature) do
    Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
    Rails.application.env_config['omniauth.auth'] = nil
  end

  config.before(:each, type: :controller) do
    @request.env['devise.mapping'] = Devise.mappings[:user] if @request
  end

  config.before(:each, type: :request) do
    Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
  end
end

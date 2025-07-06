RSpec.configure do |config|
  # Include Active Storage URL helpers in feature tests
  config.before(:each, type: :feature) do
    # Ensure Active Storage URL helpers are available
    ActiveStorage::Current.url_options = {
      host: 'localhost',
      port: 3000,
      protocol: 'http',
    }
  end

  # Include Active Storage URL helpers in views
  config.include ActiveStorage::Engine.routes.url_helpers, type: :feature
end

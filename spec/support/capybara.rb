require 'selenium-webdriver'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium, using: :headless_firefox, screen_size: [1400, 1400]
  end

  # Support for feature specs with JS
  config.before(:each, type: :feature) do |example|
    if example.metadata[:js]
      Capybara.current_driver = :headless_firefox
    end
  end

  config.after(:each, type: :feature) do
    Capybara.use_default_driver
  end
end

Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.default_normalize_ws = true
  config.server_host = 'localhost'
  config.server_port = 3001
  config.app_host = 'http://localhost:3001'
end

# Use headless Firefox for system tests
Capybara.register_driver :headless_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument('-headless')
  options.add_argument('--width=1400')
  options.add_argument('--height=1400')

  # Add preferences to avoid crashes
  options.add_preference('dom.ipc.processCount', 1)
  options.add_preference('javascript.options.showInConsole', false)
  options.add_preference('browser.tabs.remote.autostart', false)
  options.add_preference('browser.tabs.remote.autostart.2', false)

  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

# Also register a Chrome driver as fallback
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

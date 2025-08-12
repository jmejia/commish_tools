source "https://rubygems.org"

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i(windows jruby)

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
# gem "solid_cache"
gem "solid_queue"
# gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Authentication
gem "devise"
gem "omniauth"
gem "omniauth-google-oauth2"
# gem "omniauth-rails_csrf_protection"

# Background jobs using database-backed Solid Queue
# gem "sidekiq"
# gem "redis", "~> 4.0"

# API integrations
gem "httparty"
gem "faraday"
gem "faraday-multipart"
gem "faraday-retry"
gem "aws-sdk-s3"
gem 'sleeper_ff', path: '../sleeper_ff'
gem "ruby-openai"

# Audio processing
gem "streamio-ffmpeg"

# Environment variables
gem "dotenv-rails"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i(mri windows), require: "debug/prelude"
  gem "pry"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Airbnb Ruby style guide [https://github.com/airbnb/ruby]
  gem "rubocop-airbnb", require: false

  # Code quality tools
  gem "reek", require: false
  gem "simplecov", require: false

  # Testing framework
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem 'htmlbeautifier'

  # Preview emails in the browser during development
  gem "letter_opener"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Database cleanup for tests
  gem "database_cleaner-active_record"
end

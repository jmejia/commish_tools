# config/initializers/solid_cable.rb
if Rails.env.production?
  Rails.application.config.solid_cable.database = :primary
end 
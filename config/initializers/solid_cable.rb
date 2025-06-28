# config/initializers/solid_cable.rb
if Rails.env.production?
  SolidCable.config.database = :primary
end 
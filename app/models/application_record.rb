# Base class for all Active Record models in the application.
# Provides common database functionality and shared model behaviors.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end

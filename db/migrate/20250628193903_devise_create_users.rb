# frozen_string_literal: true

# Creates the core users table for the fantasy football commissioner application.
# 
# This migration sets up Devise authentication with minimal enabled modules to keep
# the user experience simple while maintaining security. Key design decisions:
# 
# - Only enables database_authenticatable, registerable, recoverable, rememberable
# - Disables trackable, confirmable, lockable to reduce friction for fantasy sports users  
# - Adds first_name, last_name for personalization (used in voice clones, team names)
# - Includes role enum for future league management permissions
# - Uses standard Devise indexing for performance on email lookups
class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |users_table|
      ## Database authenticatable
      users_table.string :email,              null: false, default: ""
      users_table.string :encrypted_password, null: false, default: ""

      ## Recoverable
      users_table.string   :reset_password_token
      users_table.datetime :reset_password_sent_at

      ## Rememberable
      users_table.datetime :remember_created_at

      ## Trackable - disabled for simplicity
      # users_table.integer  :sign_in_count, default: 0, null: false
      # users_table.datetime :current_sign_in_at
      # users_table.datetime :last_sign_in_at
      # users_table.string   :current_sign_in_ip
      # users_table.string   :last_sign_in_ip

      ## Confirmable - disabled to reduce user friction
      # users_table.string   :confirmation_token
      # users_table.datetime :confirmed_at
      # users_table.datetime :confirmation_sent_at
      # users_table.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable - disabled for user-friendly experience
      # users_table.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # users_table.string   :unlock_token # Only if unlock strategy is :email or :both
      # users_table.datetime :locked_at

      # Application-specific fields
      users_table.string :first_name  # Used for display names and voice clone personalization
      users_table.string :last_name   # Used for display names and voice clone personalization
      users_table.integer :role       # Enum: team_manager, league_owner for permissions

      users_table.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end
end

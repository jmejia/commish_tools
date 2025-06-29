# Adds OAuth fields to users table for Google authentication integration.
# 
# This migration extends the existing users table to support OAuth authentication
# alongside traditional email/password authentication. Key design decisions:
# 
# - provider: Identifies the OAuth provider (currently "google_oauth2")
# - uid: Unique identifier from the OAuth provider for this user
# - No indexes initially - can be added later if lookup performance becomes critical
# 
# This enables users to sign up/sign in with Google accounts, reducing friction
# for fantasy football league members while maintaining existing authentication options.
class AddOmniauthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :provider, :string    # OAuth provider name (e.g., "google_oauth2")
    add_column :users, :uid, :string         # Unique ID from OAuth provider
  end
end

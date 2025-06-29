# CommishTools

A Rails application for fantasy football league commissioners.

## Google OAuth Setup

To enable Google OAuth authentication, you need to:

1. Go to the [Google Cloud Console](https://console.developers.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API
4. Go to "Credentials" and create an OAuth 2.0 Client ID
5. Set the authorized redirect URIs to include:
   - `http://localhost:3000/users/auth/google_oauth2/callback` (for development)
   - `https://yourdomain.com/users/auth/google_oauth2/callback` (for production)
6. Set these environment variables:
   ```
   GOOGLE_CLIENT_ID=your_google_client_id_here
   GOOGLE_CLIENT_SECRET=your_google_client_secret_here
   ```

## Development Setup

* Ruby version: 3.2.2

* System dependencies: PostgreSQL, Redis

* Configuration: Copy environment variables as shown above

* Database creation: `rails db:create`

* Database initialization: `rails db:migrate`

* How to run the test suite: `rspec`

* Services: Redis for background jobs

* Deployment instructions: Use Kamal for deployment

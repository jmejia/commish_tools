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
   - `https://www.commish.tools/users/auth/google_oauth2/callback` (for production)
6. Set these environment variables:
   ```
   GOOGLE_CLIENT_ID=your_google_client_id_here
   GOOGLE_CLIENT_SECRET=your_google_client_secret_here
   ```

## Development Setup

### Prerequisites
* Ruby version: 3.2.2
* System dependencies: PostgreSQL

### Getting Started

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd commish_tools
   bundle install
   ```

2. **Environment configuration:**
   Copy the environment variables shown in the Google OAuth section above.

3. **Database setup:**
   ```bash
   rails db:create
   rails db:migrate
   
   # Load Solid Queue tables for background jobs
   bin/rails runner "load Rails.root.join('db/queue_schema.rb')"
   ```

4. **Start the application:**
   ```bash
   # Recommended: Start all services together
   bin/dev
   ```
   This starts:
   - Web server on http://localhost:3000
   - Background job worker (Solid Queue)
   - CSS compilation (Tailwind)

   **Alternative - Start services individually:**
   ```bash
   rails server                    # Web server
   bin/jobs                       # Background job worker
   bin/rails tailwindcss:watch    # CSS compilation
   ```

5. **Run tests:**
   ```bash
   rspec
   ```

### Background Jobs

This app uses **Solid Queue** for database-backed background job processing:
- **Storage:** Jobs stored in PostgreSQL (no Redis required)
- **Current jobs:** Email delivery for super admin notifications
- **Future jobs:** League data synchronization, report generation
- **Monitoring:** Check `solid_queue_*` tables in your database

### Deployment

* Use Kamal for deployment

## Email Testing with Letter Opener

This application uses [letter_opener](https://github.com/ryanb/letter_opener) to preview emails in your browser during development.

### How It Works

When the application sends emails in development mode, letter_opener automatically:
- Intercepts the emails before they're sent
- Opens them in your default web browser
- Saves them to your system's temp directory

### Testing Emails

#### Method 1: Use the Test Rake Task
```bash
rake mailer:test_super_admin
```
This sends a test super admin notification email and opens it in your browser.

#### Method 2: Trigger Through the Application
1. Start the application: `bin/dev`
2. Navigate to http://localhost:3000
3. Create a user account (sign up with email/password or Google OAuth)
4. Try to connect a Sleeper account:
   - Navigate to "New League" or "Connect Sleeper"
   - Enter any Sleeper username
   - Submit the form
5. The super admin notification email will automatically open in your browser

#### Method 3: Manual Access
If emails don't open automatically, you can find them at:
- **macOS/Linux:** `/tmp/letter_opener/`
- **Windows:** `%TEMP%\letter_opener\`

Each email is saved as an HTML file that you can open in any browser.

### Email Types Available

- **Super Admin Notifications:** Sent when users request Sleeper account connections
- **User Notifications:** (Coming soon) Sent when connection requests are approved/rejected

### Troubleshooting

If emails aren't opening automatically:
1. Check that your default browser is set correctly
2. Look in the Rails console for file paths
3. Manually navigate to the temp directory
4. Try the test rake task: `rake mailer:test_super_admin`

### Production vs Development

- **Development:** Emails open in browser via letter_opener
- **Test:** Email delivery is disabled for faster test runs
- **Production:** Emails are sent normally via configured mail service

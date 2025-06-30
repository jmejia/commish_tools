namespace :mailer do
  desc "Test the super admin mailer with letter_opener"
  task test_super_admin: :environment do
    puts "Testing SuperAdminMailer..."

    # Find or create a test user and super admin
    user = User.first || User.create!(
      email: 'test@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User',
      role: :team_manager
    )

    # Ensure there's at least one super admin to receive the email
    admin_user = User.find_by(email: 'admin@example.com') || User.create!(
      email: 'admin@example.com',
      password: 'password123',
      first_name: 'Admin',
      last_name: 'User',
      role: :team_manager
    )

    SuperAdmin.find_or_create_by(user: admin_user)

    # Send the test email
    SuperAdminMailer.sleeper_connection_requested(user, 'testuser123').deliver_now

    puts "Test email sent! Check your browser for the letter_opener preview."
    puts "If your browser doesn't open automatically, check the Rails console for the URL."
  end
end

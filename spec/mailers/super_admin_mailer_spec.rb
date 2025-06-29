require "rails_helper"

RSpec.describe SuperAdminMailer, type: :mailer do
  describe "sleeper_connection_requested" do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe', email: 'user@example.com') }
    let(:super_admin_user) { create(:user, email: 'admin@example.com') }
    let!(:super_admin) { create(:super_admin, user: super_admin_user) }
    let(:mail) { SuperAdminMailer.sleeper_connection_requested(user, 'testuser123') }

    it "renders the headers" do
      expect(mail.subject).to eq("New Sleeper Connection Request - John Doe")
      expect(mail.to).to eq(["admin@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("John Doe")
      expect(mail.body.encoded).to include("user@example.com")
      expect(mail.body.encoded).to include("testuser123")
      expect(mail.body.encoded).to include("New Sleeper Connection Request")
    end
  end
end

require "rails_helper"

RSpec.describe SuperAdminMailer, type: :mailer do
  describe "sleeper_connection_requested" do
    let(:mail) { SuperAdminMailer.sleeper_connection_requested }

    it "renders the headers" do
      expect(mail.subject).to eq("Sleeper connection requested")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end

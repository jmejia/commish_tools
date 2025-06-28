require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "GET /" do
    context "when user is not authenticated" do
      it "returns http success" do
        get "/"
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is authenticated" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "redirects to leagues path" do
        get "/"
        expect(response).to redirect_to(leagues_path)
      end
    end
  end
end

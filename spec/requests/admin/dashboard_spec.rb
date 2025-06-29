require 'rails_helper'

RSpec.describe 'Admin::Dashboard', type: :request do
  describe 'GET /admin/dashboard' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get admin_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated but not super admin' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'redirects to root with access denied message' do
        get admin_dashboard_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end
    end

    context 'when user is a super admin' do
      let(:user) { create(:user) }
      let!(:super_admin) { create(:super_admin, user: user) }

      before { sign_in user }

      it 'renders the dashboard' do
        get admin_dashboard_path
        expect(response).to be_successful
        expect(response.body).to include('Super Admin Dashboard')
        expect(response.body).to include(user.display_name)
      end
    end
  end
end

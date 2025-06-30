require 'rails_helper'

RSpec.describe 'Admin::SuperAdmins', type: :request do
  let(:admin_user) { create(:user) }
  let!(:admin) { create(:super_admin, user: admin_user) }

  before { sign_in admin_user }

  describe 'GET /admin/super_admins' do
    it 'renders the super admin management page' do
      get admin_super_admins_path
      expect(response).to be_successful
      expect(response.body).to include('Super Admin Management')
    end
  end

  describe 'POST /admin/super_admins' do
    let(:regular_user) { create(:user) }

    it 'creates a new super admin' do
      expect do
        post admin_super_admins_path, params: { user_id: regular_user.id }
      end.to change(SuperAdmin, :count).by(1)

      expect(response).to redirect_to(admin_super_admins_path)
      expect(flash[:notice]).to include('is now a super admin')
    end
  end

  describe 'DELETE /admin/super_admins/:id' do
    let(:other_user) { create(:user) }
    let!(:other_admin) { create(:super_admin, user: other_user) }

    it 'removes super admin status' do
      expect do
        delete admin_super_admin_path(other_admin)
      end.to change(SuperAdmin, :count).by(-1)

      expect(response).to redirect_to(admin_super_admins_path)
      expect(flash[:notice]).to include('is no longer a super admin')
    end
  end
end

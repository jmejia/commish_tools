require 'rails_helper'

RSpec.describe SuperAdmin, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_uniqueness_of(:user_id) }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }
      let!(:super_admin1) { create(:super_admin, user: user1) }
      let!(:super_admin2) { create(:super_admin, user: user2) }

      it 'returns all super admins when all users are active' do
        expect(SuperAdmin.active).to include(super_admin1, super_admin2)
      end
    end
  end

  describe 'database constraints' do
    it 'prevents duplicate super admin entries for the same user' do
      user = create(:user)
      create(:super_admin, user: user)

      expect do
        create(:super_admin, user: user)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end

require 'rails_helper'

RSpec.describe SuperAdmin, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      user = create(:user)
      super_admin = create(:super_admin, user: user)

      expect(super_admin.user).to eq(user)
      expect(super_admin).to respond_to(:user)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of user_id' do
      user = create(:user)
      create(:super_admin, user: user)

      duplicate_super_admin = build(:super_admin, user: user)
      expect(duplicate_super_admin).not_to be_valid
      expect(duplicate_super_admin.errors[:user_id]).to include('has already been taken')
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

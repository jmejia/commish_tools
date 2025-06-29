require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has one super admin with dependent destroy' do
      user = create(:user)
      expect(user).to respond_to(:super_admin)

      super_admin = create(:super_admin, user: user)
      expect(user.super_admin).to eq(super_admin)

      # Test dependent destroy
      expect { user.destroy }.to change(SuperAdmin, :count).by(-1)
    end
  end

  describe '#super_admin?' do
    let(:user) { create(:user) }

    context 'when user is not a super admin' do
      it 'returns false' do
        expect(user.super_admin?).to be false
      end
    end

    context 'when user is a super admin' do
      before { create(:super_admin, user: user) }

      it 'returns true' do
        expect(user.super_admin?).to be true
      end
    end
  end

  describe '.from_omniauth' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe',
        },
      })
    end

    context 'when user does not exist' do
      it 'creates a new user with OAuth data' do
        expect do
          User.from_omniauth(auth_hash)
        end.to change(User, :count).by(1)

        user = User.last
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
        expect(user.email).to eq('test@example.com')
        expect(user.first_name).to eq('John')
        expect(user.last_name).to eq('Doe')
        expect(user.role).to eq('team_manager')
      end
    end

    context 'when user already exists' do
      let!(:existing_user) do
        User.create!(
          provider: 'google_oauth2',
          uid: '123456789',
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe',
          password: 'password123',
          role: :team_manager
        )
      end

      it 'returns the existing user' do
        expect do
          User.from_omniauth(auth_hash)
        end.not_to change(User, :count)

        user = User.from_omniauth(auth_hash)
        expect(user).to eq(existing_user)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '.from_omniauth' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe'
        }
      })
    end

    context 'when user does not exist' do
      it 'creates a new user with OAuth data' do
        expect {
          User.from_omniauth(auth_hash)
        }.to change(User, :count).by(1)

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
        expect {
          User.from_omniauth(auth_hash)
        }.not_to change(User, :count)

        user = User.from_omniauth(auth_hash)
        expect(user).to eq(existing_user)
      end
    end
  end
end

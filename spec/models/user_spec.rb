require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'OmniAuth integration' do
    let(:auth_hash) do
      double('OmniAuth::AuthHash',
             provider: 'google_oauth2',
             uid: '123456789',
             info: double('Info',
                        email: 'test@example.com',
                        name: 'Test User'))
    end

    describe '.from_omniauth' do
      context 'when user does not exist' do
        it 'creates a new user from OAuth data' do
          expect {
            user = User.from_omniauth(auth_hash)
            expect(user).to be_persisted
            expect(user.provider).to eq('google_oauth2')
            expect(user.uid).to eq('123456789')
            expect(user.email).to eq('test@example.com')
            expect(user.name).to eq('Test User')
          }.to change(User, :count).by(1)
        end
      end

      context 'when user already exists' do
        let!(:existing_user) do
          create(:user, :with_google_oauth, uid: '123456789')
        end

        it 'finds the existing user' do
          user = User.from_omniauth(auth_hash)
          expect(user).to eq(existing_user)
          expect(User.count).to eq(1)
        end
      end
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'requires an email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'requires a password' do
      user = build(:user, password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end
end

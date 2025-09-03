require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  let(:google_token) { 'valid_google_token_123' }
  let(:mock_user_info) do
    {
      uid: 'google_uid_123',
      email: 'user@example.com',
      name: 'Google User',
      email_verified: true,
      picture: 'https://example.com/picture.jpg'
    }
  end

  before do
    # Mock the Google token verification
    allow_any_instance_of(Api::V1::AuthController).to receive(:verify_google_token)
      .with(google_token)
      .and_return(mock_user_info)
  end

  describe 'POST /api/v1/auth/google' do
    context 'when token is provided' do
      context 'when user exists' do
        let!(:existing_user) { create(:user, :with_google_oauth) }

        it 'returns success response with user data and token' do
          post '/api/v1/auth/google', params: { token: google_token }
          
          expect(response).to have_http_status(:ok)
          
          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq('success')
          expect(json_response['message']).to eq('Sign in successful')
          expect(json_response['user']['id']).to eq(existing_user.id)
          expect(json_response['user']['email']).to eq(existing_user.email)
          expect(json_response['user']['name']).to eq(existing_user.name)
          expect(json_response['token']).to be_present
          expect(json_response['token']).to be_a(String)
        end
      end

      context 'when user does not exist' do
        it 'returns not found error' do
          post '/api/v1/auth/google', params: { token: google_token }
          
          expect(response).to have_http_status(:not_found)
          
          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq('error')
          expect(json_response['message']).to eq('User not found. Please sign up first.')
          expect(json_response['code']).to eq('USER_NOT_FOUND')
        end
      end
    end

    context 'when token is missing' do
      it 'returns bad request error' do
        post '/api/v1/auth/google', params: {}
        
        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Google token is required')
      end
    end

    context 'when token verification fails' do
      before do
        allow_any_instance_of(Api::V1::AuthController).to receive(:verify_google_token)
          .with('invalid_token')
          .and_raise('Token verification failed')
      end

      it 'returns unauthorized error for invalid token' do
        post '/api/v1/auth/google', params: { token: 'invalid_token' }
        
        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Invalid Google token')
        expect(json_response['error']).to eq('Token verification failed')
      end
    end
  end

  describe 'POST /api/v1/auth/google/signup' do
    context 'when token is provided' do
      context 'when user does not exist' do
        it 'creates a new user and returns success response with token' do
          expect {
            post '/api/v1/auth/google/signup', params: { token: google_token }
          }.to change(User, :count).by(1)
          
          expect(response).to have_http_status(:created)
          
          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq('success')
          expect(json_response['message']).to eq('Sign up successful')
          
          new_user = User.last
          expect(json_response['user']['id']).to eq(new_user.id)
          expect(json_response['user']['email']).to eq('user@example.com')
          expect(json_response['user']['name']).to eq('Google User')
          expect(new_user.provider).to eq('google_oauth2')
          expect(new_user.uid).to eq('google_uid_123')
          expect(json_response['token']).to be_present
          expect(json_response['token']).to be_a(String)
        end

        context 'when email is not verified' do
          let(:mock_user_info) do
            {
              uid: 'google_uid_123',
              email: 'user@example.com',
              name: 'Google User',
              email_verified: false,
              picture: 'https://example.com/picture.jpg'
            }
          end

          it 'returns error for unverified email' do
            post '/api/v1/auth/google/signup', params: { token: google_token }
            
            expect(response).to have_http_status(:unprocessable_entity)
            
            json_response = JSON.parse(response.body)
            expect(json_response['status']).to eq('error')
            expect(json_response['message']).to eq('Email must be verified by Google')
            expect(json_response['code']).to eq('EMAIL_NOT_VERIFIED')
          end
        end
      end

      context 'when user already exists' do
        let!(:existing_user) { create(:user, :with_google_oauth) }

        it 'returns conflict error' do
          post '/api/v1/auth/google/signup', params: { token: google_token }
          
          expect(response).to have_http_status(:conflict)
          
          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq('error')
          expect(json_response['message']).to eq('User already exists. Please sign in instead.')
          expect(json_response['code']).to eq('USER_EXISTS')
        end
      end
    end

    context 'when token is missing' do
      it 'returns bad request error' do
        post '/api/v1/auth/google/signup', params: {}
        
        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Google token is required')
      end
    end

    context 'when token verification fails' do
      before do
        allow_any_instance_of(Api::V1::AuthController).to receive(:verify_google_token)
          .with('invalid_token')
          .and_raise('Token verification failed')
      end

      it 'returns unauthorized error for invalid token' do
        post '/api/v1/auth/google/signup', params: { token: 'invalid_token' }
        
        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Invalid Google token')
        expect(json_response['error']).to eq('Token verification failed')
      end
    end
  end
end

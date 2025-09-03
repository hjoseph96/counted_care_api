require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:valid_user_params) do
    {
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User'
    }
  end

  let(:existing_user) { create(:user, email: 'existing@example.com') }

  describe 'POST /api/v1/auth/signup' do
    context 'with valid parameters' do
      it 'creates a new user and returns success response with token' do
        expect {
          post '/api/v1/auth/signup', params: valid_user_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Sign up successful')
        expect(json_response['user']['email']).to eq('test@example.com')
        expect(json_response['user']['name']).to eq('Test User')
        expect(json_response['token']).to be_present
        expect(json_response['token']).to be_a(String)
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing email' do
        post '/api/v1/auth/signup', params: valid_user_params.except(:email)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Failed to create user')
      end

      it 'returns error for missing password' do
        post '/api/v1/auth/signup', params: valid_user_params.except(:password)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Failed to create user')
      end

      it 'returns error for missing name' do
        post '/api/v1/auth/signup', params: valid_user_params.except(:name)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Failed to create user')
      end
    end
  end

  describe 'POST /api/v1/auth/signin' do
    before { existing_user }

    context 'with valid credentials' do
      it 'returns success response with user data and token' do
        post '/api/v1/auth/signin', params: {
          email: 'existing@example.com',
          password: 'password123'
        }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Sign in successful')
        expect(json_response['user']['email']).to eq('existing@example.com')
        expect(json_response['token']).to be_present
        expect(json_response['token']).to be_a(String)
      end
    end

    context 'with invalid credentials' do
      it 'returns error for invalid email' do
        post '/api/v1/auth/signin', params: {
          email: 'nonexistent@example.com',
          password: 'password123'
        }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Invalid email or password')
      end

      it 'returns error for invalid password' do
        post '/api/v1/auth/signin', params: {
          email: 'existing@example.com',
          password: 'wrongpassword'
        }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Invalid email or password')
      end
    end
  end

  describe 'POST /api/v1/auth/reset-password' do
    before { existing_user }

    context 'with existing email' do
      it 'returns success response' do
        post '/api/v1/auth/reset-password', params: { email: 'existing@example.com' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Password reset instructions sent to your email')
      end
    end

    context 'with non-existing email' do
      it 'returns error response' do
        post '/api/v1/auth/reset-password', params: { email: 'nonexistent@example.com' }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('User not found')
      end
    end
  end

  describe 'POST /api/v1/auth/signout' do
    let(:user) { create(:user) }
    let(:token) { JwtService.generate_token(user) }

    context 'with valid token' do
      it 'returns success response' do
        post '/api/v1/auth/signout', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Signed out successfully')
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        post '/api/v1/auth/signout'

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Unauthorized. Valid JWT token required.')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        post '/api/v1/auth/signout', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Unauthorized. Valid JWT token required.')
      end
    end
  end

  describe 'GET /api/v1/auth/me' do
    let(:user) { create(:user) }
    let(:token) { JwtService.generate_token(user) }

    context 'with valid token' do
      it 'returns current user data' do
        get '/api/v1/auth/me', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['id']).to eq(user.id)
        expect(json_response['email']).to eq(user.email)
        expect(json_response['name']).to eq(user.name)
        expect(json_response['provider']).to eq(user.provider)
        expect(json_response['uid']).to eq(user.uid)
        expect(json_response['created_at']).to be_present
        expect(json_response['updated_at']).to be_present
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        get '/api/v1/auth/me'

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Unauthorized. Valid JWT token required.')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        get '/api/v1/auth/me', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Unauthorized. Valid JWT token required.')
      end
    end

    context 'with OAuth user' do
      let(:oauth_user) { create(:user, :with_google_oauth) }
      let(:oauth_token) { JwtService.generate_token(oauth_user) }

      it 'returns OAuth user data including provider and uid' do
        get '/api/v1/auth/me', headers: { 'Authorization' => "Bearer #{oauth_token}" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['id']).to eq(oauth_user.id)
        expect(json_response['email']).to eq(oauth_user.email)
        expect(json_response['name']).to eq(oauth_user.name)
        expect(json_response['provider']).to eq('google_oauth2')
        expect(json_response['uid']).to eq('google_uid_123')
        expect(json_response['created_at']).to be_present
        expect(json_response['updated_at']).to be_present
      end
    end
  end
end

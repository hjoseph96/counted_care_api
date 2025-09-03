require 'rails_helper'

RSpec.describe 'Api::V1::Recipients', type: :request do
  let(:user) { create(:user) }
  let(:token) { JwtService.generate_token(user) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/recipients' do
    context 'when authenticated' do
      before do
        # Create some care recipients for the user
        create_list(:care_recipient, 3, user: user)
        # Create some care recipients for another user (should not appear)
        other_user = create(:user, email: 'other@example.com')
        create_list(:care_recipient, 2, user: other_user)
      end

      it 'returns paginated list of user\'s care recipients' do
        get '/api/v1/recipients', headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['recipients'].length).to eq(3)
        expect(json_response['data']['pagination']).to be_present
        expect(json_response['data']['pagination']['current_page']).to eq(1)
        expect(json_response['data']['pagination']['total_pages']).to eq(1)
        expect(json_response['data']['pagination']['total_count']).to eq(3)
        expect(json_response['data']['pagination']['per_page']).to eq(25)
      end

      it 'respects page parameter' do
        # Create more recipients to test pagination
        create_list(:care_recipient, 30, user: user)
        
        get '/api/v1/recipients', params: { page: 2 }, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['data']['pagination']['current_page']).to eq(2)
        expect(json_response['data']['pagination']['total_pages']).to be > 1
      end

      it 'respects per_page parameter' do
        get '/api/v1/recipients', params: { per_page: 2 }, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['data']['recipients'].length).to eq(2)
        expect(json_response['data']['pagination']['per_page']).to eq(2)
      end

      it 'orders recipients by created_at desc' do
        get '/api/v1/recipients', headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        recipients = json_response['data']['recipients']
        expect(recipients.length).to be >= 1
        
        # Check that they're ordered by created_at desc
        timestamps = recipients.map { |r| Time.parse(r['created_at']) }
        expect(timestamps).to eq(timestamps.sort.reverse)
      end

      it 'only returns recipients belonging to the authenticated user' do
        get '/api/v1/recipients', headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        recipients = json_response['data']['recipients']
        recipient_ids = recipients.map { |r| r['id'] }
        
        # All returned recipients should belong to the authenticated user
        user_recipient_ids = user.care_recipients.pluck(:id)
        expect(recipient_ids).to match_array(user_recipient_ids)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized error' do
        get '/api/v1/recipients'

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Unauthorized. Valid JWT token required.')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        get '/api/v1/recipients', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Unauthorized. Valid JWT token required.')
      end
    end
  end

  describe 'POST /api/v1/recipients' do
    context 'when authenticated' do
      let(:valid_params) do
        {
          recipient: {
            name: 'John Doe',
            relationship: 'Father',
            insurance_info: 'Blue Cross Blue Shield',
            conditions: ['Diabetes', 'Hypertension']
          }
        }
      end

      it 'creates a new care recipient' do
        expect {
          post '/api/v1/recipients', params: valid_params, headers: headers
        }.to change(CareRecipient, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Care recipient created successfully')
        expect(json_response['data']['name']).to eq('John Doe')
        expect(json_response['data']['relationship']).to eq('Father')
        expect(json_response['data']['insurance_info']).to eq('Blue Cross Blue Shield')
        expect(json_response['data']['conditions']).to eq(['Diabetes', 'Hypertension'])
      end

      it 'associates the recipient with the authenticated user' do
        post '/api/v1/recipients', params: valid_params, headers: headers

        expect(response).to have_http_status(:created)
        
        recipient = CareRecipient.last
        expect(recipient.user).to eq(user)
      end

      it 'returns error for missing name' do
        invalid_params = valid_params.deep_dup
        invalid_params[:recipient][:name] = nil

        post '/api/v1/recipients', params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Failed to create care recipient')
        expect(json_response['errors']).to include("Name can't be blank")
      end

      it 'returns error for missing relationship' do
        invalid_params = valid_params.deep_dup
        invalid_params[:recipient][:relationship] = nil

        post '/api/v1/recipients', params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Failed to create care recipient')
        expect(json_response['errors']).to include("Relationship can't be blank")
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized error' do
        post '/api/v1/recipients', params: { recipient: { name: 'Test' } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/recipients/:id' do
    let(:recipient) { create(:care_recipient, user: user) }
    let(:update_params) do
      {
        recipient: {
          name: 'Updated Name',
          insurance_info: 'Updated Insurance'
        }
      }
    end

    context 'when authenticated' do
      it 'updates the care recipient' do
        patch "/api/v1/recipients/#{recipient.id}", params: update_params, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Care recipient updated successfully')
        expect(json_response['data']['name']).to eq('Updated Name')
        expect(json_response['data']['insurance_info']).to eq('Updated Insurance')
      end

      it 'cannot update recipient belonging to another user' do
        other_user = create(:user, email: 'other@example.com')
        other_recipient = create(:care_recipient, user: other_user)

        patch "/api/v1/recipients/#{other_recipient.id}", params: update_params, headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it 'returns error for invalid updates' do
        invalid_params = update_params.deep_dup
        invalid_params[:recipient][:name] = nil

        patch "/api/v1/recipients/#{recipient.id}", params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Failed to update care recipient')
        expect(json_response['errors']).to include("Name can't be blank")
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized error' do
        patch "/api/v1/recipients/#{recipient.id}", params: update_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'rate limiting' do
    it 'applies rate limiting to index action' do
      # Make multiple requests to trigger rate limiting
      1001.times do
        get '/api/v1/recipients', headers: headers
      end
      
      # Next request should be rate limited
      get '/api/v1/recipients', headers: headers
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'applies rate limiting to create action' do
      valid_params = { recipient: { name: 'Test', relationship: 'Test' } }
      
      # Make multiple requests to trigger rate limiting
      101.times do
        post '/api/v1/recipients', params: valid_params, headers: headers
      end
      
      # Next request should be rate limited
      post '/api/v1/recipients', params: valid_params, headers: headers
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'applies rate limiting to update action' do
      recipient = create(:care_recipient, user: user)
      update_params = { recipient: { name: 'Updated' } }
      
      # Make multiple requests to trigger rate limiting
      201.times do
        patch "/api/v1/recipients/#{recipient.id}", params: update_params, headers: headers
      end
      
      # Next request should be rate limited
      patch "/api/v1/recipients/#{recipient.id}", params: update_params, headers: headers
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end

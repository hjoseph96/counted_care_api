require 'rails_helper'

RSpec.describe 'Health Check API', type: :request do
  describe 'GET /api/v1/health' do
    it 'returns healthy status' do
      get '/api/v1/health'
      
      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('healthy')
      expect(json_response['timestamp']).to be_present
      expect(json_response['uptime']).to be_present
      expect(json_response['environment']).to eq(Rails.env)
    end

    it 'is not rate limited' do
      # Make multiple requests to ensure it's not rate limited
      100.times do
        get '/api/v1/health'
        expect(response).to have_http_status(:ok)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end

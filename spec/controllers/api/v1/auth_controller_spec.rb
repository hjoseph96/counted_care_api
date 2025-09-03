require 'rails_helper'

RSpec.describe Api::V1::AuthController, type: :controller do
  describe '#verify_google_token' do
    let(:controller) { described_class.new }
    let(:client_id) { Rails.application.credentials.google[:client_id] }
    let(:valid_token) { 'valid_google_id_token' }
    let(:mock_payload) do
      {
        'sub' => 'google_user_123',
        'email' => 'test@example.com',
        'name' => 'Test User',
        'email_verified' => true,
        'picture' => 'https://example.com/picture.jpg',
        'aud' => client_id,
        'iat' => Time.now.to_i,
        'exp' => (Time.now + 1.hour).to_i
      }
    end

    before do
      # Mock the Google ID Token verifier
      @mock_verifier = double('GoogleIDToken::Validator')
      allow(GoogleIDToken::Validator).to receive(:new).and_return(@mock_verifier)
      
      # No need to mock credentials since we're using the real ones
    end

    context 'with valid token' do
      before do
        allow(@mock_verifier).to receive(:check).with(valid_token, client_id).and_return(mock_payload)
      end

      it 'returns user information from token' do
        result = controller.send(:verify_google_token, valid_token)
        
        expect(result[:uid]).to eq('google_user_123')
        expect(result[:email]).to eq('test@example.com')
        expect(result[:name]).to eq('Test User')
        expect(result[:email_verified]).to be true
        expect(result[:picture]).to eq('https://example.com/picture.jpg')
      end
    end

    context 'with invalid token' do
      before do
        allow(@mock_verifier).to receive(:check).with(valid_token, client_id).and_return(nil)
      end

      it 'raises an error' do
        expect {
          controller.send(:verify_google_token, valid_token)
        }.to raise_error('Invalid token')
      end
    end

    context 'with signature error' do
      before do
        allow(@mock_verifier).to receive(:check).with(valid_token, client_id)
          .and_raise(GoogleIDToken::SignatureError)
      end

      it 'raises signature error' do
        expect {
          controller.send(:verify_google_token, valid_token)
        }.to raise_error('Token signature verification failed')
      end
    end

    context 'with expired token' do
      before do
        allow(@mock_verifier).to receive(:check).with(valid_token, client_id)
          .and_raise(GoogleIDToken::ExpiredTokenError)
      end

      it 'raises expired error' do
        expect {
          controller.send(:verify_google_token, valid_token)
        }.to raise_error('Token has expired')
      end
    end

    context 'with audience mismatch' do
      before do
        allow(@mock_verifier).to receive(:check).with(valid_token, client_id)
          .and_raise(GoogleIDToken::AudienceMismatchError)
      end

      it 'raises audience mismatch error' do
        expect {
          controller.send(:verify_google_token, valid_token)
        }.to raise_error('Token audience mismatch')
      end
    end

    context 'with other errors' do
      before do
        allow(@mock_verifier).to receive(:check).with(valid_token, client_id)
          .and_raise(StandardError, 'Unknown error')
      end

      it 'raises generic error' do
        expect {
          controller.send(:verify_google_token, valid_token)
        }.to raise_error('Token verification failed')
      end
    end
  end
end

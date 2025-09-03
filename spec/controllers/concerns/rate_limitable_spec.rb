require 'rails_helper'

RSpec.describe RateLimitable do
  # Create a test controller that includes the concern
  let(:test_controller_class) do
    Class.new(ApplicationController) do
      include RateLimitable
      
      def index
        render json: { status: 'success' }
      end
      
      def show
        render json: { status: 'success' }
      end
      
      # Override rate limit methods for testing
      def ip_rate_limit
        5
      end
      
      def ip_rate_period
        1.hour
      end
      
      def user_rate_limit
        10
      end
      
      def user_rate_period
        1.hour
      end
    end
  end

  let(:controller) { test_controller_class.new }
  let(:request) { double('request', ip: '192.168.1.1') }
  let(:response) { double('response', headers: {}) }

  before do
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:response).and_return(response)
    allow(controller).to receive(:controller_name).and_return('test')
    allow(controller).to receive(:action_name).and_return('index')
    allow(controller).to receive(:current_user).and_return(nil)
    allow(controller).to receive(:render)
    allow(controller).to receive(:request).and_return(request)
  end

  describe '#check_rate_limits' do
    context 'when IP rate limit is exceeded' do
      before do
        allow(RateLimitService).to receive(:check_ip_rate_limit).and_return(false)
      end

      it 'renders rate limit exceeded response' do
        expect(controller).to receive(:render).with(
          hash_including(
            json: hash_including(
              status: 'error',
              message: 'Rate limit exceeded. Please try again later.',
              code: 'RATE_LIMIT_EXCEEDED'
            ),
            status: :too_many_requests
          )
        )
        
        controller.send(:check_rate_limits)
      end
    end

    context 'when IP rate limit is not exceeded' do
      before do
        allow(RateLimitService).to receive(:check_ip_rate_limit).and_return(true)
      end

      it 'does not render rate limit response' do
        expect(controller).not_to receive(:render)
        controller.send(:check_rate_limits)
      end
    end

    context 'when user is authenticated and rate limit is exceeded' do
      let(:user) { double('user', id: 123) }
      
      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(RateLimitService).to receive(:check_ip_rate_limit).and_return(true)
        allow(RateLimitService).to receive(:check_user_rate_limit).and_return(false)
      end

      it 'renders rate limit exceeded response' do
        expect(controller).to receive(:render).with(
          hash_including(
            json: hash_including(
              status: 'error',
              message: 'Rate limit exceeded. Please try again later.',
              code: 'RATE_LIMIT_EXCEEDED'
            ),
            status: :too_many_requests
          )
        )
        
        controller.send(:check_rate_limits)
      end
    end
  end

  describe '#remaining_requests' do
    before do
      allow(RateLimitService).to receive(:remaining_ip_requests).and_return(3)
    end

    context 'when user is not authenticated' do
      it 'returns only IP rate limit info' do
        result = controller.send(:remaining_requests)
        
        expect(result).to eq({ ip: 3 })
      end
    end

    context 'when user is authenticated' do
      let(:user) { double('user', id: 123) }
      
      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(RateLimitService).to receive(:remaining_user_requests).and_return(7)
      end

      it 'returns both IP and user rate limit info' do
        result = controller.send(:remaining_requests)
        
        expect(result).to eq({ ip: 3, user: 7 })
      end
    end
  end

  describe '#add_rate_limit_headers' do
    let(:user) { double('user', id: 123) }
    
    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(RateLimitService).to receive(:remaining_ip_requests).and_return(3)
      allow(RateLimitService).to receive(:remaining_user_requests).and_return(7)
      allow(Time).to receive(:current).and_return(Time.new(2023, 1, 1, 12, 0, 0))
    end

    it 'adds rate limit headers to response' do
      controller.send(:add_rate_limit_headers)
      
      expect(response.headers['X-RateLimit-Limit-IP']).to eq('5')
      expect(response.headers['X-RateLimit-Remaining-IP']).to eq('3')
      expect(response.headers['X-RateLimit-Limit-User']).to eq('10')
      expect(response.headers['X-RateLimit-Remaining-User']).to eq('7')
    end
  end
end

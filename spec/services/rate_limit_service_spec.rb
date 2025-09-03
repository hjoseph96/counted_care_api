require 'rails_helper'

RSpec.describe RateLimitService do
  let(:user_id) { rand(1000..9999) }
  let(:ip) { "192.168.#{rand(1..254)}.#{rand(1..254)}" }
  let(:action) { "test_action_#{rand(1000..9999)}" }
  let(:limit) { 5 }
  let(:period) { 1.hour }

  before do
    # Clear cache before each test
    Rails.cache.clear
  end

  after do
    # Clear cache after each test
    Rails.cache.clear
  end

  # Helper method to wait for cache expiration
  def wait_for_cache_expiration
    sleep(0.1) # Small delay to ensure cache operations complete
  end

  describe '.check_user_rate_limit' do
    it 'allows requests within limit' do
      expect(RateLimitService.check_user_rate_limit(user_id, action, limit, period)).to be true
    end

    it 'blocks requests exceeding limit' do
      # Make limit requests (should all succeed)
      limit.times do
        expect(RateLimitService.check_user_rate_limit(user_id, action, limit, period)).to be true
      end
      
      # Next request should be blocked
      expect(RateLimitService.check_user_rate_limit(user_id, action, limit, period)).to be false
    end

    it 'resets after period expires' do
      # Make some requests
      RateLimitService.check_user_rate_limit(user_id, action, limit, period)
      
      # Wait for cache to expire (use shorter period for testing)
      short_period = 0.1.seconds
      RateLimitService.check_user_rate_limit(user_id, action, limit, short_period)
      
      # Wait for expiration
      wait_for_cache_expiration
      
      # Should be able to make requests again
      expect(RateLimitService.check_user_rate_limit(user_id, action, limit, short_period)).to be true
    end
  end

  describe '.check_ip_rate_limit' do
    it 'allows requests within limit' do
      expect(RateLimitService.check_ip_rate_limit(ip, action, limit, period)).to be true
    end

    it 'blocks requests exceeding limit' do
      # Make limit requests (should all succeed)
      limit.times do
        expect(RateLimitService.check_ip_rate_limit(ip, action, limit, period)).to be true
      end
      
      # Next request should be blocked
      expect(RateLimitService.check_ip_rate_limit(ip, action, limit, period)).to be false
    end
  end

  describe '.remaining_user_requests' do
    it 'returns correct remaining count' do
      # Make 2 requests
      2.times { RateLimitService.check_user_rate_limit(user_id, action, limit, period) }
      
      expect(RateLimitService.remaining_user_requests(user_id, action, limit, period)).to eq(3)
    end

    it 'returns 0 when limit exceeded' do
      # Make limit requests
      limit.times { RateLimitService.check_user_rate_limit(user_id, action, limit, period) }
      
      expect(RateLimitService.remaining_user_requests(user_id, action, limit, period)).to eq(0)
    end
  end

  describe '.remaining_ip_requests' do
    it 'returns correct remaining count' do
      # Make 2 requests
      2.times { RateLimitService.check_ip_rate_limit(ip, action, limit, period) }
      
      expect(RateLimitService.remaining_ip_requests(ip, action, limit, period)).to eq(3)
    end
  end

  describe '.reset_user_rate_limit' do
    it 'resets the rate limit counter' do
      # Make some requests
      RateLimitService.check_user_rate_limit(user_id, action, limit, period)
      
      # Reset
      RateLimitService.reset_user_rate_limit(user_id, action)
      
      # Should be able to make limit requests again
      expect(RateLimitService.check_user_rate_limit(user_id, action, limit, period)).to be true
    end
  end

  describe '.reset_ip_rate_limit' do
    it 'resets the rate limit counter' do
      # Make some requests
      RateLimitService.check_ip_rate_limit(ip, action, limit, period)
      
      # Reset
      RateLimitService.reset_ip_rate_limit(ip, action)
      
      # Should be able to make limit requests again
      expect(RateLimitService.check_ip_rate_limit(ip, action, limit, period)).to be true
    end
  end

  describe '.ban_user' do
    it 'bans a user for specified duration' do
      RateLimitService.ban_user(user_id, action, 1.hour)
      wait_for_cache_expiration
      
      expect(RateLimitService.user_banned?(user_id, action)).to be true
    end

    it 'unbans a user' do
      RateLimitService.ban_user(user_id, action, 1.hour)
      RateLimitService.unban_user(user_id, action)
      
      expect(RateLimitService.user_banned?(user_id, action)).to be false
    end
  end

  describe '.ban_ip' do
    it 'bans an IP for specified duration' do
      RateLimitService.ban_ip(ip, action, 1.hour)
      wait_for_cache_expiration
      
      expect(RateLimitService.ip_banned?(ip, action)).to be true
    end

    it 'unbans an IP' do
      RateLimitService.ban_ip(ip, action, 1.hour)
      RateLimitService.unban_ip(ip, action)
      
      expect(RateLimitService.ip_banned?(ip, action)).to be false
    end
  end
end

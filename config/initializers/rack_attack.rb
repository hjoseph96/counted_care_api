class Rack::Attack
  # Skip rate limiting in test environment
  unless Rails.env.test?
    # Use Redis for storage if available, otherwise fall back to memory
    if ENV['REDIS_URL'].present?
      Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'])
    end

    # Rate limiting by IP address
    throttle('requests by ip', limit: 300, period: 5.minutes) do |req|
      req.ip unless req.path.start_with?('/api/v1/health')
    end

    # Stricter rate limiting for authentication endpoints
    throttle('auth requests by ip', limit: 10, period: 1.minute) do |req|
      if req.path.match?(%r{^/api/v1/auth/(signin|signup|google|reset-password)})
        req.ip
      end
    end

    # Rate limiting for Google OAuth endpoints (more strict)
    throttle('google oauth by ip', limit: 5, period: 1.minute) do |req|
      if req.path.match?(%r{^/api/v1/auth/google})
        req.ip
      end
    end

    # Rate limiting for password reset (very strict)
    throttle('password reset by ip', limit: 3, period: 1.hour) do |req|
      if req.path.match?(%r{^/api/v1/auth/reset-password})
        req.ip
      end
    end

    # Rate limiting by user ID for authenticated requests
    throttle('authenticated requests by user', limit: 1000, period: 1.hour) do |req|
      if req.path.start_with?('/api/v1/') && req.get?
        # Extract user ID from JWT token if present
        token = req.get_header('HTTP_AUTHORIZATION')&.gsub(/^Bearer\s+/, '')
        if token
          begin
            payload = JwtService.decode(token)
            payload['user_id'] if payload
          rescue
            nil
          end
        end
      end
    end

    # Block suspicious IPs (basic DDoS protection)
    blocklist('block suspicious ips') do |req|
      # Block IPs that make too many requests in a short period
      Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 20, findtime: 1.minute, bantime: 1.hour) do
        req.path.start_with?('/api/v1/') && !req.path.start_with?('/api/v1/health')
      end
    end

    # Block requests with suspicious patterns
    blocklist('block suspicious requests') do |req|
      # Block requests with suspicious headers
      suspicious_headers = req.env.select { |k, v| k.start_with?('HTTP_') && v.to_s.length > 1000 }
      !suspicious_headers.empty?

      # Block requests with suspicious user agents
      user_agent = req.user_agent.to_s.downcase
      suspicious_agents = ['bot', 'crawler', 'spider', 'scraper', 'curl', 'wget', 'python', 'java']
      suspicious_agents.any? { |agent| user_agent.include?(agent) }
    end

    # Block requests with malformed paths
    blocklist('block malformed paths') do |req|
      # Block paths with excessive length
      req.path.length > 500

      # Block paths with suspicious characters
      req.path.match?(/[<>\"'&;]/)

      # Block paths with excessive dots (directory traversal attempts)
      req.path.count('.') > 10
    end

    # Block requests with suspicious query parameters
    blocklist('block suspicious query params') do |req|
      # Block requests with excessive query parameters
      req.params.keys.length > 50

      # Block requests with suspicious parameter values
      req.params.values.any? { |v| v.to_s.length > 1000 }
    end

    # Block requests with suspicious body content
    blocklist('block suspicious body content') do |req|
      # Block requests with excessive body size
      content_length = req.get_header('CONTENT_LENGTH')
      if content_length
        content_length.to_i > 10.megabytes
      end
    end

    # Custom response for blocked requests
    self.blocklisted_responder = lambda do |env|
      [429, {'Content-Type' => 'application/json'}, [{
        status: 'error',
        message: 'Too many requests. Please try again later.',
        code: 'RATE_LIMIT_EXCEEDED'
      }.to_json]]
    end

    # Custom response for throttled requests
    self.throttled_responder = lambda do |env|
      [429, {'Content-Type' => 'application/json'}, [{
        status: 'error',
        message: 'Rate limit exceeded. Please try again later.',
        code: 'RATE_LIMIT_EXCEEDED'
      }.to_json]]
    end

    # Log blocked requests for monitoring
    ActiveSupport::Notifications.subscribe('rack.attack.blocklist') do |name, start, finish, request_id, payload|
      req = payload[:request]
      Rails.logger.warn "Rack::Attack blocked request: #{req.ip} - #{req.path} - #{req.user_agent}"
    end

    # Log throttled requests for monitoring
    ActiveSupport::Notifications.subscribe('rack.attack.throttle') do |name, start, finish, request_id, payload|
      req = payload[:request]
      Rails.logger.warn "Rack::Attack throttled request: #{req.ip} - #{req.path} - #{req.user_agent}"
    end
  end
end

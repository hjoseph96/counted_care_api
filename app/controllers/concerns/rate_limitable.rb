module RateLimitable
  extend ActiveSupport::Concern

  included do
    before_action :check_rate_limits
  end

  private

  def check_rate_limits
    # Check IP-based rate limiting
    unless check_ip_rate_limit
      render_rate_limit_exceeded
      return
    end

    # Check user-based rate limiting if authenticated
    if current_user && !check_user_rate_limit
      render_rate_limit_exceeded
      return
    end
  end

  def check_ip_rate_limit
    action = "#{controller_name}##{action_name}"
    RateLimitService.check_ip_rate_limit(request.ip, action, ip_rate_limit, ip_rate_period)
  end

  def check_user_rate_limit
    action = "#{controller_name}##{action_name}"
    RateLimitService.check_user_rate_limit(current_user.id, action, user_rate_limit, user_rate_period)
  end

  def render_rate_limit_exceeded
    render json: {
      status: 'error',
      message: 'Rate limit exceeded. Please try again later.',
      code: 'RATE_LIMIT_EXCEEDED',
      retry_after: rate_limit_retry_after
    }, status: :too_many_requests
  end

  # Override these methods in controllers for custom rate limits
  def ip_rate_limit
    100 # Default: 100 requests
  end

  def ip_rate_period
    1.hour # Default: 1 hour
  end

  def user_rate_limit
    1000 # Default: 1000 requests
  end

  def user_rate_period
    1.hour # Default: 1 hour
  end

  def rate_limit_retry_after
    # Return retry-after header value
    ip_period = ip_rate_period
    user_period = user_rate_period
    [ip_period, user_period].min
  end

  # Helper methods for controllers
  def remaining_requests
    if current_user
      {
        ip: RateLimitService.remaining_ip_requests(request.ip, "#{controller_name}##{action_name}", ip_rate_limit, ip_rate_period),
        user: RateLimitService.remaining_user_requests(current_user.id, "#{controller_name}##{action_name}", user_rate_limit, user_rate_period)
      }
    else
      {
        ip: RateLimitService.remaining_ip_requests(request.ip, "#{controller_name}##{action_name}", ip_rate_limit, ip_rate_period)
      }
    end
  end

  def add_rate_limit_headers
    remaining = remaining_requests
    
    response.headers['X-RateLimit-Limit-IP'] = ip_rate_limit.to_s
    response.headers['X-RateLimit-Remaining-IP'] = remaining[:ip].to_s
    response.headers['X-RateLimit-Reset-IP'] = (Time.current + ip_rate_period).to_i.to_s
    
    if current_user
      response.headers['X-RateLimit-Limit-User'] = user_rate_limit.to_s
      response.headers['X-RateLimit-Remaining-User'] = remaining[:user].to_s
      response.headers['X-RateLimit-Reset-User'] = (Time.current + user_rate_period).to_i.to_s
    end
  end
end

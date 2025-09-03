# Rate Limiting and Anti-DDoS Protection

This document describes the comprehensive rate limiting and anti-DDoS measures implemented in the Counted Care API.

## Overview

The API implements multiple layers of protection against abuse, DDoS attacks, and excessive usage:

1. **Rack::Attack** - Global rate limiting and blocking
2. **RateLimitService** - Programmatic rate limiting
3. **RateLimitable concern** - Controller-level rate limiting
4. **Health check endpoint** - Excluded from rate limiting

## Rack::Attack Configuration

### Global Rate Limits

- **General requests**: 300 requests per IP per 5 minutes
- **Authentication endpoints**: 10 requests per IP per minute
- **Google OAuth**: 5 requests per IP per minute
- **Password reset**: 3 requests per IP per hour
- **Authenticated requests**: 1000 requests per user per hour

### Anti-DDoS Protection

- **IP blocking**: Automatic blocking of IPs making excessive requests
- **Suspicious patterns**: Blocks requests with malformed paths, excessive headers, etc.
- **Bot detection**: Blocks common bot user agents
- **Request size limits**: Blocks requests larger than 10MB

### Blocking Rules

```ruby
# Suspicious headers (>1000 characters)
# Suspicious user agents (bot, crawler, spider, etc.)
# Malformed paths (>500 characters, suspicious characters)
# Excessive query parameters (>50 parameters)
# Large request bodies (>10MB)
```

## RateLimitService

Programmatic rate limiting service for custom logic:

```ruby
# Check user rate limits
RateLimitService.check_user_rate_limit(user_id, action, limit, period)

# Check IP rate limits
RateLimitService.check_ip_rate_limit(ip, action, limit, period)

# Get remaining requests
RateLimitService.remaining_user_requests(user_id, action, limit, period)

# Ban/unban users and IPs
RateLimitService.ban_user(user_id, action, duration)
RateLimitService.ban_ip(ip, action, duration)
```

## RateLimitable Concern

Include in controllers for automatic rate limiting:

```ruby
class UsersController < ApplicationController
  include RateLimitable
  
  # Customize rate limits per action
  def ip_rate_limit
    case action_name
    when 'signin', 'signup'
      10 # 10 attempts per hour
    when 'reset_password'
      3  # 3 attempts per hour
    else
      100 # Default
    end
  end
  
  def ip_rate_period
    1.hour
  end
end
```

### Rate Limit Headers

Controllers automatically include rate limit headers:

```
X-RateLimit-Limit-IP: 100
X-RateLimit-Remaining-IP: 95
X-RateLimit-Reset-IP: 1640995200
X-RateLimit-Limit-User: 1000
X-RateLimit-Remaining-User: 950
X-RateLimit-Reset-User: 1640995200
```

## Configuration

### Environment Variables

```bash
# Redis for rate limiting (optional)
REDIS_URL=redis://localhost:6379/0
```

### Cache Store

- **With Redis**: Uses Redis for distributed rate limiting
- **Without Redis**: Falls back to memory store (development only)

## API Endpoints

### Health Check

```
GET /api/v1/health
```

**Excluded from rate limiting** - Always accessible for monitoring.

### Admin Rate Limit Management

```
GET    /api/v1/admin/rate_limits
GET    /api/v1/admin/rate_limits?ip=192.168.1.1
GET    /api/v1/admin/rate_limits?user_id=123
POST   /api/v1/admin/rate_limits/ban_ip
POST   /api/v1/admin/rate_limits/unban_ip
POST   /api/v1/admin/rate_limits/ban_user
POST   /api/v1/admin/rate_limits/unban_user
```

**Requires admin access** (email contains 'admin').

## Monitoring and Logging

### Rack::Attack Events

```ruby
# Blocked requests
ActiveSupport::Notifications.subscribe('rack.attack.blocklist') do |name, start, finish, request_id, payload|
  req = payload[:request]
  Rails.logger.warn "Blocked: #{req.ip} - #{req.path}"
end

# Throttled requests
ActiveSupport::Notifications.subscribe('rack.attack.throttle') do |name, start, finish, request_id, payload|
  req = payload[:request]
  Rails.logger.warn "Throttled: #{req.ip} - #{req.path}"
end
```

### Response Headers

All rate-limited responses include:

```json
{
  "status": "error",
  "message": "Rate limit exceeded. Please try again later.",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 3600
}
```

## Testing

### Running Tests

```bash
# All tests
bundle exec rspec

# Rate limiting tests only
bundle exec rspec spec/services/rate_limit_service_spec.rb
bundle exec rspec spec/controllers/concerns/rate_limitable_spec.rb
bundle exec rspec spec/requests/api/v1/health_spec.rb
```

### Test Coverage

- RateLimitService functionality
- RateLimitable concern behavior
- Health check endpoint
- Rate limit headers
- Ban/unban functionality

## Production Considerations

### Redis Setup

For production, ensure Redis is properly configured:

```bash
# Install Redis
sudo apt-get install redis-server

# Configure Redis
sudo nano /etc/redis/redis.conf

# Set memory limits and persistence
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000

# Restart Redis
sudo systemctl restart redis
```

### Monitoring

Monitor rate limiting effectiveness:

- Track blocked/throttled requests
- Monitor Redis memory usage
- Set up alerts for unusual patterns
- Log rate limit violations

### Scaling

- Use Redis cluster for high availability
- Implement rate limit sharing across app instances
- Consider CDN-level rate limiting for edge protection

## Troubleshooting

### Common Issues

1. **Rate limits too strict**: Adjust limits in Rack::Attack configuration
2. **Redis connection errors**: Check REDIS_URL and Redis server status
3. **Memory usage**: Monitor cache store memory consumption
4. **False positives**: Review blocking rules and adjust thresholds

### Debug Mode

Enable debug logging in development:

```ruby
# config/environments/development.rb
config.log_level = :debug
```

### Manual Testing

Test rate limiting manually:

```bash
# Test IP rate limiting
curl -X POST http://localhost:3000/api/v1/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Check rate limit headers
curl -I -X POST http://localhost:3000/api/v1/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

## Security Notes

- Rate limiting is not a substitute for proper authentication
- Monitor for bypass attempts (IP spoofing, etc.)
- Regularly review and update blocking rules
- Implement proper logging for security audits
- Consider implementing CAPTCHA for repeated failures

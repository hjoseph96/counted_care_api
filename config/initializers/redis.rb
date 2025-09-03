# Redis configuration for rate limiting and caching
if ENV['REDIS_URL'].present?
  $redis = Redis.new(url: ENV['REDIS_URL'])
  
  # Configure Rails cache to use Redis
  Rails.application.config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    connect_timeout: 30,
    read_timeout: 0.2,
    write_timeout: 0.2,
    reconnect_attempts: 1,
    error_handler: -> (method:, returning:, exception:) {
      Rails.logger.error "Redis error: #{exception.class} - #{exception.message}"
    }
  }
else
  # Fallback to memory store for development
  Rails.application.config.cache_store = :memory_store, { size: 64.megabytes }
end

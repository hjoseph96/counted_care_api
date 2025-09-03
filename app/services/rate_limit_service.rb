class RateLimitService
  class << self
    # Check if a user has exceeded rate limits for a specific action
    def check_user_rate_limit(user_id, action, limit, period)
      cache_key = "rate_limit:user:#{user_id}:#{action}"
      current_count = Rails.cache.read(cache_key) || 0
      
      if current_count >= limit
        false
      else
        new_count = current_count + 1
        Rails.cache.write(cache_key, new_count, expires_in: period)
        true
      end
    end

    # Check if an IP has exceeded rate limits for a specific action
    def check_ip_rate_limit(ip, action, limit, period)
      cache_key = "rate_limit:ip:#{ip}:#{action}"
      current_count = Rails.cache.read(cache_key) || 0
      
      if current_count >= limit
        false
      else
        new_count = current_count + 1
        Rails.cache.write(cache_key, new_count, expires_in: period)
        true
      end
    end

    # Get remaining requests for a user
    def remaining_user_requests(user_id, action, limit, period)
      cache_key = "rate_limit:user:#{user_id}:#{action}"
      current_count = Rails.cache.read(cache_key) || 0
      [0, limit - current_count].max
    end

    # Get remaining requests for an IP
    def remaining_ip_requests(ip, action, limit, period)
      cache_key = "rate_limit:ip:#{ip}:#{action}"
      current_count = Rails.cache.read(cache_key) || 0
      [0, limit - current_count].max
    end

    # Reset rate limit for a user
    def reset_user_rate_limit(user_id, action)
      cache_key = "rate_limit:user:#{user_id}:#{action}"
      Rails.cache.delete(cache_key)
    end

    # Reset rate limit for an IP
    def reset_ip_rate_limit(ip, action)
      cache_key = "rate_limit:ip:#{ip}:#{action}"
      Rails.cache.delete(cache_key)
    end

    # Check if a user is temporarily banned
    def user_banned?(user_id, action)
      cache_key = "ban:user:#{user_id}:#{action}"
      Rails.cache.exist?(cache_key)
    end

    # Ban a user temporarily
    def ban_user(user_id, action, duration = 1.hour)
      cache_key = "ban:user:#{user_id}:#{action}"
      Rails.cache.write(cache_key, true, expires_in: duration)
    end

    # Unban a user
    def unban_user(user_id, action)
      cache_key = "ban:user:#{user_id}:#{action}"
      Rails.cache.delete(cache_key)
    end

    # Check if an IP is temporarily banned
    def ip_banned?(ip, action)
      cache_key = "ban:ip:#{ip}:#{action}"
      Rails.cache.exist?(cache_key)
    end

    # Ban an IP temporarily
    def ban_ip(ip, action, duration = 1.hour)
      cache_key = "ban:ip:#{ip}:#{action}"
      Rails.cache.write(cache_key, true, expires_in: duration)
    end

    # Unban an IP
    def unban_ip(ip, action)
      cache_key = "ban:ip:#{ip}:#{action}"
      Rails.cache.delete(cache_key)
    end
  end
end

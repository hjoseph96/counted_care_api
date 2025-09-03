source "https://rubygems.org"

gem "rails", "~> 8.0.2"
gem "pg", "~> 1.6"
gem "puma", ">= 5.0"

gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

gem "devise"
  gem "jwt"
  gem "omniauth"
  gem "omniauth-google-oauth2"
  gem "google-id-token"
  gem "money-rails"
  gem "http"
  gem "kaminari"
gem "rack-attack"
gem "redis"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "pry-rails"
  gem "rspec-rails"
  gem "factory_bot_rails"
end

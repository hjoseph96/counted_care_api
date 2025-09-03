Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'omniauth_callbacks'
  }
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :recipients, only: [:index, :create, :update]
      
      # Health check (excluded from rate limiting)
      get 'health', to: 'health#check'
      
      # Google OAuth routes (legacy POST endpoints)
      post 'auth/google', to: 'auth#google_signin'
      post 'auth/google/signup', to: 'auth#google_signup'
      
      # New OAuth flow routes (recommended)
      get 'oauth/google', to: 'oauth#google'
      get 'oauth/google/redirect', to: 'oauth#google' # Direct redirect with ?redirect=true
      get 'oauth/google/callback', to: 'oauth#google_callback'
      
      # User authentication routes
      post 'auth/signin', to: 'users#signin'
      post 'auth/signup', to: 'users#signup'
      post 'auth/reset-password', to: 'users#reset_password'
      post 'auth/signout', to: 'users#signout'
      get 'auth/me', to: 'users#me'
      
      # Admin routes for rate limiting management
      namespace :admin do
        resources :rate_limits, only: [:index, :show] do
          collection do
            post :ban_ip
            post :unban_ip
            post :ban_user
            post :unban_user
          end
        end
      end
    end
  end

  # Defines the root path route ("/")
  root "welcome#index"
end

module Api
  module V1
    class UsersController < ApplicationController
      include JwtAuthenticatable
      include RateLimitable
      skip_before_action :authenticate_user_from_token!, only: [:signin, :signup, :reset_password]
      
      after_action :add_rate_limit_headers

      
      # POST /api/v1/auth/signin
      def signin
        user = User.find_by(email: params[:email])
        
        if user&.valid_password?(params[:password])
          render json: {
            status: 'success',
            message: 'Sign in successful',
            user: {
              id: user.id,
              email: user.email,
              name: user.name
            },
            token: JwtService.generate_token(user)
          }, status: :ok
        else
          render json: {
            status: 'error',
            message: 'Invalid email or password'
          }, status: :unauthorized
        end
      end

      # POST /api/v1/auth/signup
      def signup
        user = User.new(
          email: params[:email],
          password: params[:password],
          name: params[:name]
        )

        if user.save
          render json: {
            status: 'success',
            message: 'Sign up successful',
            user: {
              id: user.id,
              email: user.email,
              name: user.name
            },
            token: JwtService.generate_token(user)
          }, status: :created
        else
          render json: {
            status: 'error',
            message: 'Failed to create user',
            errors: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/reset-password
      def reset_password
        user = User.find_by(email: params[:email])
        
        if user
          # Generate reset token and send email
          user.send_reset_password_instructions
          render json: {
            status: 'success',
            message: 'Password reset instructions sent to your email'
          }, status: :ok
        else
          render json: {
            status: 'error',
            message: 'User not found'
          }, status: :not_found
        end
      end

      # POST /api/v1/auth/signout
      def signout
        # JWT token will be revoked by Devise JWT
        render json: {
          status: 'success',
          message: 'Signed out successfully'
        }, status: :ok
      end

      # GET /api/v1/auth/me - Get current user data
      def me
        render json: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name,
          provider: current_user.provider,
          uid: current_user.uid,
          created_at: current_user.created_at,
          updated_at: current_user.updated_at
        }, status: :ok
      end
    end

    private

    # Custom rate limits for authentication endpoints
    def ip_rate_limit
      case action_name
      when 'signin', 'signup'
        10 # 10 attempts per hour
      when 'reset_password'
        3 # 3 attempts per hour
      when 'me'
        1000 # 1000 requests per hour for user data
      else
        100 # Default for other actions
      end
    end

    def ip_rate_period
      case action_name
      when 'signin', 'signup'
        1.hour
      when 'reset_password'
        1.hour
      else
        1.hour
      end
    end

    def user_rate_limit
      case action_name
      when 'signout'
        50 # 50 signouts per hour
      when 'me'
        1000 # 1000 requests per hour for user data
      else
        1000 # Default for other actions
      end
    end

    def user_rate_period
      case action_name
      when 'signout'
        1.hour
      else
        1.hour
      end
    end
  end
end

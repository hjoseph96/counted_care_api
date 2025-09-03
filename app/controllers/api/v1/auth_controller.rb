module Api
  module V1
    class AuthController < ApplicationController
      def google_signin
        token = params[:token]
        
        if token.blank?
          render json: {
            status: 'error',
            message: 'Google token is required'
          }, status: :bad_request
          return
        end

        begin
          # Verify the Google token and extract user info
          user_info = verify_google_token(token)
          
          # Find existing user
          user = User.find_by(provider: 'google_oauth2', uid: user_info[:uid])
          
          if user
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
              message: 'User not found. Please sign up first.',
              code: 'USER_NOT_FOUND'
            }, status: :not_found
          end
        rescue => e
          render json: {
            status: 'error',
            message: 'Invalid Google token',
            error: e.message
          }, status: :unauthorized
        end
      end

      def google_signup
        token = params[:token]
        
        if token.blank?
          render json: {
            status: 'error',
            message: 'Google token is required'
          }, status: :bad_request
          return
        end

        begin
          # Verify the Google token and extract user info
          user_info = verify_google_token(token)
          
          # Check if user already exists
          existing_user = User.find_by(provider: 'google_oauth2', uid: user_info[:uid])
          
          if existing_user
            render json: {
              status: 'error',
              message: 'User already exists. Please sign in instead.',
              code: 'USER_EXISTS'
            }, status: :conflict
            return
          end

          # Verify email is verified by Google
          unless user_info[:email_verified]
            render json: {
              status: 'error',
              message: 'Email must be verified by Google',
              code: 'EMAIL_NOT_VERIFIED'
            }, status: :unprocessable_entity
            return
          end

          # Create new user
          user = User.create!(
            email: user_info[:email],
            name: user_info[:name],
            provider: 'google_oauth2',
            uid: user_info[:uid],
            password: SecureRandom.hex(16) # Generate random password for OAuth users
          )

          if user.persisted?
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
        rescue => e
          render json: {
            status: 'error',
            message: 'Invalid Google token',
            error: e.message
          }, status: :unauthorized
        end
      end

      private

      def verify_google_token(token)
        # Get the Google client ID from credentials
        client_id = Rails.application.credentials.google[:client_id]
        
        # Create a new Google ID Token verifier
        verifier = GoogleIDToken::Validator.new
        
        # Verify the token and extract payload
        payload = verifier.check(token, client_id)
        
        if payload
          # Token is valid, extract user information
          {
            uid: payload['sub'],           # Google's unique user ID
            email: payload['email'],       # User's email address
            name: payload['name'],         # User's full name
            email_verified: payload['email_verified'], # Whether email is verified
            picture: payload['picture']    # User's profile picture URL
          }
        else
          raise 'Invalid token'
        end
      rescue GoogleIDToken::SignatureError
        raise 'Token signature verification failed'
      rescue GoogleIDToken::ExpiredTokenError
        raise 'Token has expired'
      rescue GoogleIDToken::AudienceMismatchError
        raise 'Token audience mismatch'
      rescue RuntimeError => e
        if e.message == 'Invalid token'
          raise 'Invalid token'
        else
          Rails.logger.error "Google token verification failed: #{e.message}"
          raise 'Token verification failed'
        end
      rescue => e
        Rails.logger.error "Google token verification failed: #{e.message}"
        raise 'Token verification failed'
      end
    end
  end
end 
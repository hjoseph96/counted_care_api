module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user_from_token!
  end

  private

  def authenticate_user_from_token!
    token = extract_token_from_header
    return render_unauthorized unless token

    @current_user = JwtService.user_from_token(token)
    render_unauthorized unless @current_user
  end

  def extract_token_from_header
    header = request.headers['Authorization']
    return nil unless header

    # Extract token from "Bearer <token>" format
    header.split(' ').last if header.start_with?('Bearer ')
  end

  def render_unauthorized
    render json: {
      status: 'error',
      message: 'Unauthorized. Valid JWT token required.'
    }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end

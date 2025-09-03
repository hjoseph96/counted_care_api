class JwtService
  SECRET_KEY = Rails.application.credentials.dig(:jwt, :secret)
  ALGORITHM = 'HS256'

  def self.encode(payload)
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  def self.decode(token)
    JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })[0]
  rescue JWT::DecodeError
    nil
  end

  def self.generate_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      exp: 30.days.from_now.to_i
    }
    encode(payload)
  end

  def self.valid_token?(token)
    decode(token).present?
  end

  def self.user_from_token(token)
    payload = decode(token)

    return nil unless payload
    
    User.find_by(id: payload['user_id'])
  end
end

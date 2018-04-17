# frozen_string_literal: true

# Generate token
module Token
  ACCESS_PERIOD = 9000
  POST_PERIOD = 8_000

  def access_token(user_id:)
    encode_token(user_id, ACCESS_PERIOD, 'access')
  end

  def registration_token(user_id:)
    encode_token(user_id, POST_PERIOD, 'registration')
  end

  def recovery_token(user_id:)
    encode_token(user_id, POST_PERIOD, 'recovery')
  end

  def encode_token(user_id, period, type)
    JWT.encode(
      {
        user: user_id,
        type: type,
        exp: Time.new.to_i + period
      },
      ENV['JWT_SECRET']
    )
  end

  def decode_token(token)
    JWT.decode(token, ENV['JWT_SECRET']).first
  rescue JWT::DecodeError
    nil
  end
end

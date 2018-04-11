# frozen_string_literal: true

# All user in site
class User < ApplicationRecord
  has_secure_password

  def check_refresh_token(token)
    refresh_token == token
  end

  def set_refresh_token
    token = encode_refresh_token
    self.refresh_token = token
    save
    token
  end

  private

  def encode_refresh_token
    JWT.encode(
      {
        user: id,
        type: 'refresh',
        exp: (Time.new + 1.day).to_i
      },
      ENV['JWT_SECRET']
    )
  end
end

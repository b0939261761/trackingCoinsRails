# frozen_string_literal: true

# All user in site
class User < ApplicationRecord
  after_save :refresh_bot, if: :telegram_activated && :saved_change_to_lang?
  after_destroy :refresh_bot, if: :telegram_activated

  has_many :monitoring_accounts

  has_secure_password

  def bot_session
    Telegram::WebhookController.session_store
  end

  def bot_session_key
    self.telegram_chat_id.to_s
  end

  def refresh_bot
    values = bot_session.read(bot_session_key) || {}
    values['refresh_bot'] = true
    values = bot_session.write(bot_session_key, values)
  end

  def check_refresh_token(token)
    refresh_token == token
  end

  def set_refresh_token
    token = encode_refresh_token
    self.refresh_token = token
    save
    token
  end

  def telegram_full_name
    "#{self.telegram_first_name} #{self.telegram_last_name}"
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

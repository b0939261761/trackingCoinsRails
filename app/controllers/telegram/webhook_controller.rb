# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def start(*)
    activate
  end

  def activate(*)
    response = from ? "Hello #{}!" : 'Hi there!'
    user = User.find_by(telegram_username: from['username'])

    text = 'Register fail '

    if user &&
      user.update(telegram_chat_id: from['id'],
                  telegram_first_name: from['first_name'] || '',
                  telegram_last_name: from['last_name'] || '',
                  telegram_activated: true)
      text = 'Register done '
    end

    respond_with :message, text: text
  end
end

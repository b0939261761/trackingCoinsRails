# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def start(*)
    respond_with :message, text: 'HI'
  end
end

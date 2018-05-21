# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::CallbackQueryContext
  # include Telegram::Bot::UpdatesController::TypedUpdate

  before_action :check_callback_query

  def check_callback_query
    throw :abort if payload_type == 'message' && action_name.end_with?('_callback_query')
  end
  # before_action do |controller|
  #   # unless payload_type == 'callback_query'

  #     p controller.action_name
  # end

  def settings(*)
    button = Telegram::Bot::Types::InlineKeyboardButton.new(
      text: "🔄 Refresh  settings",
      callback_data: 'refresh_settings:', url: '')
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button]])

    respond_with :message, text: 'Settings', reply_markup: markup.to_hash
  end

  def callback_query(data)
    respond_with :message, text: 'callback_query'
  end

  def refresh_settings_callback_query(*)
    # return unless payload_type == 'callback_query'

    # respond_with :message, text: 'refresh_settings_callback_query'
    # respond_with :message, text: payload_type
    answer_callback_query(I18n.t(:saved))

  end

end

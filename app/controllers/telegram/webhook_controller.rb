# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController

  include Telegram::Bot::UpdatesController::CallbackQueryContext
  # include Telegram::Bot::UpdatesController::TypedUpdate
  use_session!
  before_action :set_locale


  def settings(*)
    button = Telegram::Bot::Types::InlineKeyboardButton.new(
      text: "🔄 #{I18n.t(:refresh_settings)}", callback_data: 'refresh_settings:dds', url: '')
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button]])

    respond_with :message, text: I18n.t(:settings), reply_markup: markup.to_hash
  end

  def refresh_settings_callback_query(data)
    session.delete(:lang)
    answer_callback_query(I18n.t(:saved))
  end

  def callback_query(data)
  end

  def help(*)
    url = ENV['WEB_URL'].gsub('localhost', '127.0.0.1')
    button = Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{I18n.t(:go_to)} Reality Coins", url: url)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button]])

    respond_with :message, text: I18n.t(:more_infomation), reply_markup: markup.to_hash
  end

  def start(*)
    text = I18n.t(:register_fail)

    if user &&
      user.update(telegram_chat_id: from['id'],
                  telegram_first_name: from['first_name'] || '',
                  telegram_last_name: from['last_name'] || '',
                  telegram_activated: true)
      text = I18n.t(:register_done)
    end

    respond_with :message, text: text
  end



  private

  def session_key
    "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
  end

  def set_locale
    I18n.locale = lang
  end


  def user
    @user ||= User.find_by(telegram_username: from['username'])
  end

  def lang
    session[:lang] ||= user.lang
  end

end

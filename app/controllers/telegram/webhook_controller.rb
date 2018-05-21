# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController

  include Telegram::Bot::UpdatesController::CallbackQueryContext
  # include Telegram::Bot::UpdatesController::TypedUpdate

  use_session!
  before_action :set_locale


  def message(data)
    case data['text']
    when button_activate_title
      activate
    when button_refresh_settings_title
      refresh_settings
    when button_help_title
      help
    end
  end

  def help(*)
    url = ENV['WEB_URL'].gsub('localhost', '127.0.0.1')
    button = Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{I18n.t(:go_to)} Reality Coins", url: url)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button]]).to_hash

    respond_with :message, text: I18n.t(:more_infomation), reply_markup: markup
  end

  def activate(*)
    markup = refresh_all_settings

    text = I18n.t(:register_fail)

    if user &&
      user.update(telegram_chat_id: from['id'],
                  telegram_first_name: from['first_name'] || '',
                  telegram_last_name: from['last_name'] || '',
                  telegram_activated: true)
      text = I18n.t(:register_done)
    end

    respond_with :message, text: text, reply_markup: markup
  end

  def start(*)
    activate
  end

  def refresh_settings(*)
    markup = refresh_all_settings
    respond_with :message, text: I18n.t(:saved), reply_markup: markup
  end

  private

  def button_activate_title
    "☑️ #{I18n.t(:activate)}"
  end

  def button_refresh_settings_title
    "🔄 #{I18n.t(:refresh_settings)}"
  end

  def button_help_title
    "ℹ️ #{I18n.t(:help)}"
  end

  def refresh_all_settings
    session.delete(:lang)
    @user = nil
    set_locale
    buttons = [[button_activate_title, button_refresh_settings_title], [button_help_title]]
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: buttons, resize_keyboard: true, one_time_keyboard: true).to_hash
  end

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

# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::CallbackQueryContext
  include Telegram::Bot::UpdatesController::MessageContext
  include NotificationsAdditional
  include TelegramNotifications
  include TelegramSettings
  include TelegramActivate
  include TelegramChangeNotification

  use_session!
  before_action :refresh_bot, if: -> { session[:refresh_bot] }
  before_action :set_locale

  def test!(*)
  end

  def message(data)
    case data['text']
    when button_notifications_title
      notifications!
    when button_exchange_rates_title
      respond_with :message, text: 'В разработке', reply_markup: main_keyboard
    when button_settings_title
      settings!
    when button_activate_title
      start!
    when button_help_title
      help!
    when button_cancel_title
      respond_with :message, text: I18n.t(:done), reply_markup: main_keyboard
    end
  end

  def help!
    url = ENV['WEB_URL'].gsub('localhost', '127.0.0.1')
    button = Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{I18n.t(:go_to)} Cryptonot", url: url)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button]]).to_hash

    respond_with :message, text: I18n.t(:more_infomation), reply_markup: markup
  end

  def start!
    activate
  end

  private

  def button_activate_title
    "☑️ #{I18n.t(:activate)}"
  end

  def button_cancel_title
    "❌ #{I18n.t(:cancel)}"
  end

  def button_next_title
    "▶️ #{I18n.t(:next)}"
  end

  def refresh_bot
    if session[:refresh_bot]
      refresh_all_settings
      session.delete(:refresh_bot)

      respond_with :message, text: I18n.t(:bot_refresh), reply_markup: main_keyboard
    end
  end

  def refresh_all_settings
    @user = nil
    clear_user_info
    clear_add_notification
    set_locale
  end

  def clear_user_info
    session.delete(:lang)
    session.delete(:user_id)

    clear_add_user
    clear_add_notification
    @user = nil
    set_locale
  end

  def button_cancel_click
    clear_add_notification
    respond_with :message, text: I18n.t(:done), reply_markup: main_keyboard
  end

  def main_keyboard
    buttons = session[:user_id] \
      ? [[button_notifications_title, button_exchange_rates_title],
         [button_settings_title, button_help_title]] \
      : [[button_activate_title, button_help_title]]

    setup_button(buttons)
  end

  def button_notifications_title
    "🔔 #{I18n.t(:notifications)}"
  end

  def button_exchange_rates_title
    "💲 #{I18n.t(:exchange_rates)}"
  end

  def button_settings_title
    "🛠 #{I18n.t(:settings)}"
  end

  def button_help_title
    "ℹ️ #{I18n.t(:help)}"
  end

  def button_save_title
    "💾 #{I18n.t(:save)}"
  end

  def setup_button(buttons)
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: buttons, resize_keyboard: true, one_time_keyboard: true).to_hash
  end

  def set_locale
    I18n.locale = lang
  end

  def user
    @user ||= User.find_by(telegram_username: from['username'])
    session[:user_id] = @user&.id
    @user
  end

  def session_key
    if (subject = from || chat) then "#{subject['id']}" end
  end

  def lang
    session[:lang] ||= user&.lang || lang_from_update
  end

  def lang_from_update
    from['language_code']&.downcase&.include?('ru') ? 'ru' : 'en'
  end
end



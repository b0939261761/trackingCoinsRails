# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::CallbackQueryContext
  include Telegram::Bot::UpdatesController::MessageContext
  include NotificationsAdditional
  include TelegramAddNotification
  include TelegramChangeNotification

  use_session!
  before_action :set_locale

  def test!(*)
  end

  def message(data)
    case data['text']
    when button_activate_title
      activate!
    when button_refresh_settings_title
      refresh_settings
    when button_help_title
      help!
    when button_add_notification_title
      clear_add_notification
      new_currency_pair
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

  def activate!
    refresh_all_settings

    text = I18n.t(:register_fail)

    if user&.update(telegram_chat_id: from['id'],
                    telegram_first_name: from['first_name'] || '',
                    telegram_last_name: from['last_name'] || '',
                    telegram_activated: true)
      text = I18n.t(:register_done)

      markup = main_keyboard
    else
      markup = setup_button([[button_activate_title, button_help_title]])
    end

    respond_with :message, text: text, reply_markup: markup
  end

  def start!
    activate!
  end

  private

  def refresh_settings
    refresh_all_settings
    respond_with :message, text: I18n.t(:saved), reply_markup: main_keyboard
  end

  def button_activate_title
    "☑️ #{I18n.t(:activate)}"
  end

  def button_refresh_settings_title
    "🔄 #{I18n.t(:refresh_settings)}"
  end

  def button_help_title
    "ℹ️ #{I18n.t(:help)}"
  end

  def button_add_notification_title
    "➕ #{I18n.t(:add_notification)}"
  end

  def button_cancel_title
    "❌ #{I18n.t(:cancel)}"
  end

  def button_next_title
    "▶️ #{I18n.t(:next)}"
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
    clear_add_notification
    @user = nil
    set_locale
  end

  def button_cancel_click
    clear_add_notification
    respond_with :message, text: I18n.t(:done), reply_markup: main_keyboard
  end

  def main_keyboard
    setup_button([[button_add_notification_title, button_refresh_settings_title],
                 [button_help_title]])
  end

  def setup_button(buttons)
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
    if user
      session[:user_id] ||= user.id
      session[:lang] ||= user.lang
    else

      session[:lang] = from['language_code']&.downcase&.include?('ru') ? 'ru' : 'en'
    end
  end
end



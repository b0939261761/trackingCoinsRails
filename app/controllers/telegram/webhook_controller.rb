# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::CallbackQueryContext
  include Telegram::Bot::UpdatesController::MessageContext
  include NotificationsAdditional
  include TelegramNotifications
  include TelegramFarmsMonitoring
  include TelegramSettings
  include TelegramActivate
  include TelegramChangeNotification

  require 'net/http'


  use_session!
  before_action :refresh_bot, if: -> { session[:refresh_bot] }
  before_action :set_locale

  APP_NAME = ENV['APP_NAME']

  def test!(*)
  end

  def message(data)
    case data['text']
    when button_notifications_title
      notifications!
    when button_exchange_rates_title
      exchange_rates!
    when button_farms_monitoring_title
      farms_monitoring!
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
    first_name = "☎️ #{I18n.t(:support)} #{APP_NAME}"
    phone_number = ENV['TELEGRAM_SUPPORT_PHONE']
    button_text = "#{I18n.t(:go_to)} #{APP_NAME}"
    url = ENV['WEB_URL'].gsub('localhost', '127.0.0.1')
    button = Telegram::Bot::Types::InlineKeyboardButton.new(text: button_text, url: url)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button]]).to_hash

    respond_with :contact, phone_number: phone_number, first_name: first_name, reply_markup: markup
  end

  def start!
    activate
  end

  def exchange_rates!(*args)
    response = args&.join(' ')

    if response == button_cancel_title
      button_cancel_click
      return
    end

    symbol = response.upcase

    if symbol.include?('/')
      sql = <<-SQL
        SELECT bb.name as exchange_name,
               cc.price,
               cc.close_time
        FROM pairs aa
        LEFT JOIN exchanges bb ON bb.id = aa.exchange_id
        CROSS JOIN LATERAL (
          SELECT price,
                 close_time
          FROM prices
          WHERE pair_id = aa.id
          ORDER BY close_time desc
          LIMIT 1
        ) cc
        WHERE aa.symbol = '#{symbol}'
        ORDER BY 1
      SQL

      prices = JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json, symbolize_names: true)
      if prices.any?
        text = ''

        prices.each do |price|
          close_time = Time.parse(price[:close_time]).strftime('%d.%m.%y %H:%M:%S')
          text += "#{price[:exchange_name]} *#{price[:price]}* `#{close_time}`\n"
        end

        respond_with :message, text: text, reply_markup: main_keyboard, parse_mode: 'Markdown'
        return
      end
    end

    markup = setup_button([[button_cancel_title]])
    respond_with :message, text: I18n.t(:ask_enter_pair), reply_markup: markup
    save_context :exchange_rates!
  end

  private

  def button_activate_title
    "☑️ #{I18n.t(:activate)}"
  end

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
    clear_monitoring_farms
    set_locale
  end

  def clear_monitoring_farms
    session.delete(:new_nanopool_address)
  end

  def clear_user_info
    session.delete(:lang)
    session.delete(:user_id)

    clear_add_user
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
         [button_farms_monitoring_title], \
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

  def button_farms_monitoring_title
    "🔥 #{I18n.t(:farms_monitoring)}"
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



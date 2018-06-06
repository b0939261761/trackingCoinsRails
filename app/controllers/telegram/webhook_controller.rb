# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::CallbackQueryContext
  include Telegram::Bot::UpdatesController::MessageContext
  include NotificationsAdditional

  use_session!
  context_to_action!
  before_action :set_locale

  def new_currency_pair
    markup = setup_button([[button_cancel_title]])
    respond_with :message, text: I18n.t(:ask_enter_pair), reply_markup: markup
    save_context :new_currency_pair
  end

  context_handler :new_currency_pair do |*args|
    response = args&.join(' ')

    if response == button_cancel_title
      button_cancel_click
      return
    end

    symbol = response.upcase

    if symbol.include?('/')
      exchanges_list = exchanges(symbol: symbol)

      if exchanges_list.present?
        session[:new_currency_pair] = symbol
        session[:exchanges_list] = exchanges_list
        session[:new_exchanges] = []
        new_exchanges
        return
      end
    end

    new_currency_pair
  end

  def new_exchanges
    markup = setup_button(session[:exchanges_list].map{ |o| o[:name] }.each_slice(3).to_a +
      [[button_all_exchanges_title] +
      (session[:new_exchanges].any? ? [button_next_title] : []) +
      [button_cancel_title]])
    text = "#{I18n.t(:ask_enter_exchange)}\n" +
      (session[:new_exchanges].any? \
        ? "*#{I18n.t(:selected_exchanges)}* `#{session[:new_exchanges].map{ |o| o[:name] }.join(', ')}`" \
        : '')
    respond_with :message, text: text, reply_markup: markup, parse_mode: 'Markdown'
    save_context :new_exchanges
  end

  context_handler :new_exchanges do |*args|
    response = args&.join(' ')

    if response == button_cancel_title
      button_cancel_click
      return
    elsif response == button_all_exchanges_title
      session[:new_exchanges] += session[:exchanges_list]
      new_direction
      return
    elsif response == button_next_title
      new_direction
      return
    end

    exchanges_list = session[:exchanges_list]
    exchange = exchanges_list.select { |o| o[:name].upcase == response.upcase }

    if exchange
      new_exchanges_list = exchanges_list - exchange

      if new_exchanges_list.any?
        session[:exchanges_list] = new_exchanges_list
        session[:new_exchanges] += exchange
      else
        new_direction
        return
      end
    end

    new_exchanges
  end

  def new_direction
    markup = setup_button([[button_less_title, button_above_title], [button_cancel_title]])
    respond_with :message, text: I18n.t(:ask_enter_direction), reply_markup: markup
    save_context :new_direction
  end

  context_handler :new_direction do |*args|
    response = args&.join(' ')

    if response == button_cancel_title
      button_cancel_click
      return
    elsif response == button_less_title
      session[:new_direction] = 'less'
      new_price
      return
    elsif response == button_above_title
      session[:new_direction] = 'above'
      new_price
      return
    end

    new_direction
  end

  def new_price
    markup = setup_button([(session[:new_price] ? [button_save_title] : []) +
                           [button_cancel_title]])
    text = "#{I18n.t(:ask_enter_price)}\n" +
      (session[:new_price] \
        ? "*#{I18n.t(:selected_price)}* `#{'%0.10f' % session[:new_price]}`" \
        : '')
    respond_with :message, text: text, reply_markup: markup, parse_mode: 'Markdown'
    save_context :new_price
  end

  context_handler :new_price do |*args|
    response = args&.join(' ')

    if response == button_cancel_title
      button_cancel_click
      return
    elsif response == button_save_title
      sql_new_exchanges = [ ]
      values_for_sql = {
        user_id: session[:user_id],
        symbol: session[:new_currency_pair],
        direction: session[:new_direction],
        price: session[:new_price],
        activated: true
      }

      session[:new_exchanges].each do |o|
        sql_new_exchanges << notifications_sql_value(values_for_sql.merge(exchange_id: o[:id]))
      end

      notifications_sql_insert(values: sql_new_exchanges, ids: [0])

      clear_add_notification
      respond_with :message, text: "✔️ #{I18n.t(:notification_created)}", reply_markup: main_keyboard
      return
    end

    price = ('%0.10f' % args[0].to_f).to_f
    session[:new_price] = price if price.nonzero?

    new_price
  end

  def test(*)
  end

  def message(data)
    case data['text']
    when button_activate_title
      activate
    when button_refresh_settings_title
      refresh_settings
    when button_help_title
      help
    when button_add_notification_title
      clear_add_notification
      new_currency_pair
    when button_cancel_title
      respond_with :message, text: I18n.t(:done), reply_markup: main_keyboard
    end
  end

  def disable_notification_callback_query(id, *)
    Notification.where(id: id).update_all(activated: false)
    answer_callback_query(I18n.t(:done))
  end

  def remove_notification_callback_query(id, *)
    Notification.where(id: id).delete_all
    answer_callback_query(I18n.t(:done))
  end

  def help(*)
    url = ENV['WEB_URL'].gsub('localhost', '127.0.0.1')
    button = Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{I18n.t(:go_to)} Cryptonot", url: url)
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

  def clear_add_notification
    session.delete(:new_currency_pair)
    session.delete(:exchanges_list)
    session.delete(:new_exchanges)
    session.delete(:new_direction)
    session.delete(:new_price)
  end

  def exchanges(symbol:)
    @exchanges ||= JSON.parse(exchanges_by_pair(symbol: symbol).to_json, symbolize_names: true)
  end

  def button_save_title
    "💾 #{I18n.t(:save)}"
  end

  def button_less_title
    "⬇️ #{I18n.t(:less)}"
  end

  def button_above_title
    "⬆️ #{I18n.t(:above)}"
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

  def button_all_exchanges_title
    "📃 #{I18n.t(:all_exchanges)}"
  end

  def refresh_all_settings
    session.delete(:lang)
    session.delete(:user_id)
    clear_add_notification
    @user = nil
    set_locale
    main_keyboard
  end

  def button_cancel_click
    clear_add_notification
    respond_with :message, text: I18n.t(:done), reply_markup: main_keyboard
  end

  def main_keyboard
    setup_button([[button_activate_title, button_refresh_settings_title],
                 [button_add_notification_title, button_help_title]])
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
    session[:user_id] ||= user.id
    session[:lang] ||= user.lang
  end
end

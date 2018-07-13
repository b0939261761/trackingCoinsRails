# frozen_string_literal: true

module TelegramNotifications

  def notifications!(*args)
    case args&.join(' ')
    when button_cancel_title
      button_cancel_click
      return
    when button_my_notifications_title
      my_notifications
      return
    when button_add_notification_title
      clear_add_notification
      new_currency_pair
      return
    end

    markup = setup_button([[button_my_notifications_title, button_add_notification_title],
                           [button_cancel_title]])

    respond_with :message, text: I18n.t(:selected_notifications), reply_markup: markup
    save_context :notifications!
  end

  def my_notifications
    text = ''

    notifications(user_id: session[:user_id]).each do | o |
      text += \
        "*#{o[:symbol]}* " \
        "#{o[:exchange_names].join(', ')} " \
        "#{o[:direction] == 'less' ? '⬇️' : '️️️⬆️'} " \
        "`#{'%0.10f' % o[:price].to_f}` " \
        "#{o[:activated] ? '🔔' : '🔕'}\n"
    end

    text = I18n.t(:no_data) if text.empty?
    respond_with :message, text: text, reply_markup: main_keyboard, parse_mode: 'Markdown'
  end

  def new_currency_pair(*args)
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

    markup = setup_button([[button_cancel_title]])
    respond_with :message, text: I18n.t(:ask_enter_pair), reply_markup: markup
    save_context :new_currency_pair
  end

  def new_exchanges(*args)
    response = args&.join(' ')

    case response
    when button_cancel_title
      button_cancel_click
      return
    when button_all_exchanges_title
      session[:new_exchanges] += session[:exchanges_list]
      new_direction
      return
    when button_next_title
      new_direction
      return
    end

    exchanges_list = session[:exchanges_list]
    exchange = exchanges_list.select { |o| o[:name].upcase == response.upcase }

    if exchange.any?
      new_exchanges_list = exchanges_list - exchange

      session[:exchanges_list] = new_exchanges_list
      session[:new_exchanges] += exchange

      unless new_exchanges_list.any?
        new_direction
        return
      end
    end

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

  def new_direction(*args)
    response = args&.join(' ')

    case response
    when button_cancel_title
      button_cancel_click
      return
    when button_less_title
      session[:new_direction] = 'less'
      new_price
      return
    when button_above_title
      session[:new_direction] = 'above'
      new_price
      return
    end

    markup = setup_button([[button_less_title, button_above_title], [button_cancel_title]])
    respond_with :message, text: I18n.t(:ask_enter_direction), reply_markup: markup
    save_context :new_direction
  end

  def new_price(*args)
    response = args&.join(' ')

    case response
    when button_cancel_title
      button_cancel_click
      return
    when button_save_title
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

      notifications_sql_insert(values: sql_new_exchanges, ids: [])

      clear_add_notification
      respond_with :message, text: "✔️ #{I18n.t(:notification_created)}", reply_markup: main_keyboard
      return
    end

    price = ('%0.10f' % args[0].to_f).to_f
    session[:new_price] = price if price.nonzero?

    markup = setup_button([(session[:new_price] ? [button_save_title] : []) +
                           [button_cancel_title]])
    text = "#{I18n.t(:ask_enter_price)}\n" +
      (session[:new_price] \
        ? "*#{I18n.t(:selected_price)}* `#{'%0.10f' % session[:new_price]}`" \
        : '')
    respond_with :message, text: text, reply_markup: markup, parse_mode: 'Markdown'
    save_context :new_price
  end

  private

  def clear_add_notification
    session.delete(:new_currency_pair)
    session.delete(:exchanges_list)
    session.delete(:new_exchanges)
    session.delete(:new_direction)
    session.delete(:new_price)
  end

  def button_add_notification_title
    "➕ #{I18n.t(:add_notification)}"
  end

  def button_my_notifications_title
    "📋 #{I18n.t(:my_notifications)}"
  end

  def exchanges(symbol:)
    @exchanges ||= JSON.parse(exchanges_by_pair(symbol: symbol).to_json, symbolize_names: true)
  end

  def button_all_exchanges_title
    "📃 #{I18n.t(:all_exchanges)}"
  end

  def button_less_title
    "⬇️ #{I18n.t(:less)}"
  end

  def button_above_title
    "⬆️ #{I18n.t(:above)}"
  end
end

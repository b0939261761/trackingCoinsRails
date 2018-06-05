# frozen_string_literal: true

module TelegramAddNotification
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

      if new_exchanges_list.length
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
        user_id: user_id,
        symbol: session[:new_currency_pair],
        direction: session[:new_direction],
        price: session[:new_price],
        activated: true
      }

      session[:new_exchanges].each do |o|
        sql_new_exchanges << notifications_sql_value(values_for_sql.merge(exchange_id: o[:id]))
      end

      notifications_sql_insert(values: values, ids: [])

      clear_add_notification
      respond_with :message, text: "✔️ #{I18n.t(:notification_created)}", reply_markup: main_keyboard
      return
    end

    price = ('%0.10f' % args[0].to_f).to_f
    session[:new_price] = price if price.nonzero?

    new_price
  end

  private

  
end

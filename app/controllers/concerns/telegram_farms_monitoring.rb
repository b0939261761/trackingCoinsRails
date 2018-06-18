# frozen_string_literal: true

module TelegramFarmsMonitoring

  def farms_monitoring!(*args)
    case args&.join(' ')
    when button_cancel_title
      button_cancel_click
      return
    when button_create_title
      create_farms_monitoring
      return
    when button_remove_title
      remove_farms_monitoring
      return
    when button_view_title
      view_farms_monitoring
      return
    end

    markup = setup_button( user.nanopool_address.empty? \
      ? [[button_create_title], [button_cancel_title]] \
      : [[button_remove_title, button_view_title], [button_cancel_title]])

    respond_with :message, text: I18n.t(:farms_monitoring), reply_markup: markup
    save_context :farms_monitoring!
  end

  def create_farms_monitoring(*args)
    respond = args&.join(' ')
    case respond
    when button_cancel_title
      button_cancel_click
      return
    when button_save_title
      text = user.update(nanopool_address: session[:new_nanopool_address]) \
        ? I18n.t(:done) \
        : I18n.t(:fail)

      respond_with :message, text: text, reply_markup: main_keyboard
      session.delete(:new_nanopool_address)
      return
    end

    session[:new_nanopool_address] = respond if respond

    markup = setup_button([[button_save_title, button_cancel_title]])

    text = "#{I18n.t(:ask_enter_create_farms_monitoring)}\n" +
    (session[:new_nanopool_address] \
      ? "*#{I18n.t(:selected_create_farms_monitoring)}* `#{session[:new_nanopool_address]}`" \
      : '')
    respond_with :message, text: text, reply_markup: markup, parse_mode: 'Markdown'
    save_context :create_farms_monitoring
  end

  def remove_farms_monitoring
    text = user.update(nanopool_address: '') \
        ? I18n.t(:done) \
        : I18n.t(:fail)

    respond_with :message, text: text, reply_markup: main_keyboard
  end

  def view_farms_monitoring
    text = "*#{I18n.t(:address_account)}* `#{user.nanopool_address}`"
    respond_with :message, text: text, reply_markup: main_keyboard, parse_mode: 'Markdown'
  end

  private

  def button_create_title
    "➕ #{I18n.t(:create)}"
  end

  def button_remove_title
    "🗑 #{I18n.t(:remove)}"
  end

  def button_view_title
    "👁‍🗨󠁧󠁢󠁥󠁮󠁧󠁿 #{I18n.t(:view)}"
  end
end

# frozen_string_literal: true

module TelegramFarmsMonitoring

  NANOPOOL_URL = 'https://api.nanopool.org/v1/eth/reportedhashrates/'

  def farms_monitoring!(*args)
    case args&.join(' ')
    when button_cancel_title
      button_cancel_click
      return
    when button_create_title
      clear_monitoring_farms
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
      account = session.delete(:new_nanopool_address)
      add_monitoring_account(account: account)
      return
    end

    session[:new_nanopool_address] = respond unless respond.empty?
    account = session[:new_nanopool_address]
    markup = setup_button([[(account ? button_save_title : ''), button_cancel_title]])

    text = "#{I18n.t(:ask_enter_create_farms_monitoring)}\n" +
      (account ? "*#{I18n.t(:selected_create_farms_monitoring)}* `#{account}`" : '')
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
    text = "*#{I18n.t(:address_account)}* `#{user.nanopool_address}`\n" +
      (buttons_view_farms.length == 2 ? "*#{I18n.t(:account_not_farms)}*" : '')
    respond_with :message, text: text, reply_markup: setup_inline_button(buttons_view_farms), parse_mode: 'Markdown'
    save_context :farms_monitoring!
  end

  def farm_activated_callback_query(obj, *)
    params = JSON.parse(obj, symbolize_names: true)
    Farm.where(id: params[:farm_id]).update_all(activated: params[:activated])
    edit_message :reply_markup, reply_markup: setup_inline_button(buttons_view_farms)
  end

  def button_cancel_callback_query(*)
    bot.delete_message chat_id: payload['message']['chat']['id'], message_id: payload['message']['message_id']
    button_cancel_click
  end

  def remove_farms_callback_query(*)
    bot.delete_message chat_id: payload['message']['chat']['id'], message_id: payload['message']['message_id']
    remove_farms_monitoring
  end

  private

  def buttons_view_farms
    @buttons_view_farms ||= Proc.new {
      farms = Farm.select(:id, :name, :activated).where(user_id: user.id)

      button_remove = Telegram::Bot::Types::InlineKeyboardButton.new(url: '',
        text: "🗑 #{I18n.t(:remove_account)}", callback_data: 'remove_farms:')

      buttons = [button_remove]

      farms.each do |farm|
        buttons << [button_farm(farm_id: farm.id, text:farm.name, activated: farm.activated)]
      end

      buttons << [button_cancel_inline]
    }.call
  end

  def farms_delete
    Farm.where(user_id: user.id).delete_all
  end

  def add_monitoring_account(account:)
    if user.update(nanopool_address: account)
      farms_delete

      response = Net::HTTP.get(URI("#{NANOPOOL_URL}#{account}"))
      data = JSON.parse(response, symbolize_names: true)
      if data[:status]
        sql_val = []
        data[:data].each { |o| sql_val << "(#{user.id}, '#{o[:worker]}')" }

        if sql_val.any?
          sql = <<-SQL
            INSERT INTO farms ( user_id, name )
              VALUES #{sql_val.join(',')}
          SQL

          ActiveRecord::Base.connection.execute(sql)
        end
      end
      view_farms_monitoring
    else
      respond_with :message, text: I18n.t(:fail), reply_markup: main_keyboard
    end
  end

  def button_cancel_inline
    Telegram::Bot::Types::InlineKeyboardButton.new(
      text: button_cancel_title, callback_data: 'button_cancel:')
  end

  def button_farm(farm_id:, text:, activated:)
    obj = {farm_id: farm_id, activated: !activated}.to_json

    Telegram::Bot::Types::InlineKeyboardButton.new(
      text: "#{activated \
        ? "🔕 #{I18n.t(:disable_notification)}" \
        : "🔔 #{I18n.t(:enable_notification)}"} - "\
        "#{text}",
      callback_data: "farm_activated:#{obj}")
  end

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

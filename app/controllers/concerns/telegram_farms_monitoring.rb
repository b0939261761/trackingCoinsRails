# frozen_string_literal: true

module TelegramFarmsMonitoring
  extend ActiveSupport::Concern

  included do
    attr_accessor :monitoring_account
  end

  NANOPOOL_URL = 'https://api.nanopool.org/v1/eth/reportedhashrates/'

  def farms_monitoring!(*args)
    case args&.join(' ')
    when button_cancel_title
      button_cancel_click
      return
    when button_add_title
      clear_monitoring_farms
      create_farms_monitoring
      return
    when button_current_hashrate_title
      current_hashrate
      return
    when button_remove_title, button_view_title
      view_monitoring_accounts
      return
    end

    markup = setup_button( user.monitoring_accounts.count.zero? \
      ? [[button_add_title], [button_cancel_title]] \
      : [[button_add_title, button_remove_title],
         [button_view_title, button_current_hashrate_title],
         [button_cancel_title]])

    respond_with :message, text: I18n.t(:farms_monitoring), reply_markup: markup
    save_context :farms_monitoring!
  end

  def current_hashrate
    text = ''
    user.monitoring_accounts.each do |account|
      self.monitoring_account = account
      text += "\n*#{I18n.t(:address_account)}* `#{monitoring_account.account}`\n"

      if (current_farms = farms).any?
        current_farms.each do |f|
          text += <<~TEXT
          \s   #{I18n.t(:farm)}: *#{f[:name]}*
          \s   #{I18n.t(:current_hashrate)} `#{f[:last_hashrate]}`
          \s   ------------
          TEXT
        end
      else
        text += "*#{I18n.t(:account_not_farms)}*\n"
      end
    end

    respond_with :message, text: text, parse_mode: 'Markdown'
    save_context :farms_monitoring!
  end

  def create_farms_monitoring(*args)
    respond = args&.join(' ')
    case respond
    when button_cancel_title
      button_cancel_click
      return
    when button_save_title
      account = session.delete(:new_account)
      add_monitoring_account(account: account)
      return
    end

    session[:new_account] = respond unless respond.empty?
    account = session[:new_account]
    markup = setup_button([[(account ? button_save_title : ''), button_cancel_title]])

    text = "#{I18n.t(:ask_enter_create_farms_monitoring)}\n" +
      (account ? "*#{I18n.t(:selected_create_farms_monitoring)}* `#{account}`" : '')
    respond_with :message, text: text, reply_markup: markup, parse_mode: 'Markdown'
    save_context :create_farms_monitoring
  end

  def view_monitoring_accounts
    user.monitoring_accounts.each do |o|
      self.monitoring_account = o
      view_farms_monitoring
    end

    save_context :farms_monitoring!
  end

  def view_farms_monitoring
    @buttons_view_farms = nil
    text = "*#{I18n.t(:address_account)}* `#{monitoring_account.account}`\n" +
      (buttons_view_farms.length == 2 ? "*#{I18n.t(:account_not_farms)}*" : '')
    respond_with :message, text: text, reply_markup: setup_inline_button(buttons_view_farms), parse_mode: 'Markdown'
  end

  def farm_activated_callback_query(obj, *)
    params = JSON.parse(obj, symbolize_names: true)
    farm = Farm.find_by(id: params[:farm_id])
    if farm&.update(activated: params[:activated])
      self.monitoring_account = farm.monitoring_account
      edit_message :reply_markup, reply_markup: setup_inline_button(buttons_view_farms)
      return
    end
    respond_with :message, text: I18n.t(:fail), reply_markup: main_keyboard
  end

  def account_activated_callback_query(obj, *)
    params = JSON.parse(obj, symbolize_names: true)
    self.monitoring_account = MonitoringAccount.find_by(id: params[:monitoring_account_id])

    if monitoring_account&.update(activated: params[:activated])
      edit_message :reply_markup, reply_markup: setup_inline_button(buttons_view_farms)
      return
    end
    respond_with :message, text: I18n.t(:fail), reply_markup: main_keyboard
  end

  def button_cancel_callback_query(*)
    bot.delete_message chat_id: payload['message']['chat']['id'], message_id: payload['message']['message_id']
    button_cancel_click
  end

  def remove_farms_callback_query(monitoring_account_id, *)
    bot.delete_message chat_id: payload['message']['chat']['id'], message_id: payload['message']['message_id']

    text = MonitoringAccount.find_by(id: monitoring_account_id)&.destroy \
        ? I18n.t(:done) \
        : I18n.t(:fail)

    respond_with :message, text: text, reply_markup: main_keyboard
  end

  private

  def farms
    Farm.where(monitoring_account_id: monitoring_account.id).order(:name)
  end

  def buttons_view_farms
    @buttons_view_farms ||= Proc.new {
      id = monitoring_account.id
      activated = monitoring_account.activated

      button_remove = Telegram::Bot::Types::InlineKeyboardButton.new(
        text: "🗑 #{I18n.t(:remove_account)}", callback_data: "remove_farms:#{id}")

      obj = {monitoring_account_id: id, activated: !activated}.to_json

      button_notification = Telegram::Bot::Types::InlineKeyboardButton.new(
        text: "#{activated ? "🔕 #{I18n.t(:disable_account)}" : "🔔 #{I18n.t(:enable_account)}"}",
        callback_data: "account_activated:#{obj}")

      buttons = [[button_notification, button_remove]]

      farms.each do |farm|
        buttons << [button_farm(farm_id: farm.id, text:farm.name, activated: farm.activated)]
      end

      buttons << button_cancel_inline
    }.call
  end

  def add_monitoring_account(account:)
    begin
      uri = URI("#{NANOPOOL_URL}#{account}")
    rescue
      respond_with :message, text: I18n.t(:error_uri), reply_markup: main_keyboard
      return
    end

    begin
      response = Net::HTTP.get(uri)
      data = JSON.parse(response, symbolize_names: true)
    rescue Exception => e
      logger.error("ERROR NANOPOOL monitoring_account_ID #{account}: #{e}")
      respond_with :message, text: I18n.t(:error_connection), reply_markup: main_keyboard
      return
    end

    sql = <<-SQL
      INSERT INTO monitoring_accounts (
        user_id,
        account
      )
        VALUES (
          #{user.id},
          '#{account}'
          )
        ON CONFLICT ( user_id, account )
          DO UPDATE SET
            activated = true
        RETURNING id
    SQL

    monitoring_account_id = JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json,
      symbolize_names: true)[0][:id]

    if monitoring_account_id
      if data[:status]
        sql_val = []
        data[:data].each { |o| sql_val << "(#{monitoring_account_id}, '#{o[:worker]}')" }

        if sql_val.any?
          sql = <<-SQL
            INSERT INTO farms ( monitoring_account_id, name )
              VALUES #{sql_val.join(',')}
              ON CONFLICT ( monitoring_account_id, name )
              DO UPDATE SET
                activated = true
          SQL

          ActiveRecord::Base.connection.execute(sql)
        end
      end

      self.monitoring_account = MonitoringAccount.find_by(id: monitoring_account_id)
      view_farms_monitoring
      return
    end
    respond_with :message, text: I18n.t(:fail), reply_markup: main_keyboard
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

  def button_add_title
    "➕ #{I18n.t(:add)}"
  end

  def button_remove_title
    "🗑 #{I18n.t(:remove)}"
  end

  def button_view_title
    "👁‍🗨󠁧󠁢󠁥󠁮󠁧󠁿 #{I18n.t(:view)}"
  end

  def button_current_hashrate_title
    "⏲󠁧󠁢󠁥󠁮󠁧󠁿 #{I18n.t(:current_hashrate)}"
  end
end

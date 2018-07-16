# frozen_string_literal: true

module TelegramActivate

  def activate
    refresh_all_settings

    unless user&.update(telegram_fields)
      instuctions
      new_username
      return
    end

    respond_with :message, text: I18n.t(:register_done), reply_markup: main_keyboard
  end

  def new_username(*args)
    response = args&.join(' ')

    case response
    when button_cancel_title
      button_cancel_click
      return
    when button_next_title
      new_password
      return
    end

    session[:new_username] = args[0] if /^[[:alnum:]]{5,30}$/.match?(args[0])

    markup = setup_button([(session[:new_username] ? [button_next_title] : []) +
                          [button_cancel_title]])
    text = "#{I18n.t(:ask_enter_username)}\n" +
      (session[:new_username] \
        ? "*#{I18n.t(:selected_username)}* `#{session[:new_username]}`" \
        : '')

    respond_with :message, text: text, reply_markup: markup, parse_mode: 'Markdown'
    save_context :new_username
  end

  def new_password(*args)
    response = args&.join(' ')

    case response
    when button_cancel_title
      button_cancel_click
      return
    when button_save_title
      username = session[:new_username]
      telegram_username = from['username']
      telegram_info = telegram_fields.merge(
        { telegram_username: telegram_username,
          username: username,
          password: session[:new_password],
          lang: session[:lang],
          telegram_activated: true }
      )

      if (new_user = User.create(telegram_info))
        session[:user_id] = new_user.id

        text = I18n.t(:done)
        notification_new_registration(username: username, telegram_username: telegram_username)
      else
        text = I18n.t(:fail)
      end

      clear_add_user
      respond_with :message, text: text, reply_markup: main_keyboard
      return
    end

    session[:new_password] = args[0] if /^\S{5,31}$/.match?(args[0])

    markup = setup_button([(session[:new_password] ? [button_save_title] : []) +
                          [button_cancel_title]])
    text = "#{I18n.t(:ask_enter_password)}\n" +
      (session[:new_password] \
        ? "*#{I18n.t(:selected_password)}* `#{session[:new_password]}`" \
        : '')

    respond_with :message, text: text, reply_markup: markup, parse_mode: 'Markdown'
    save_context :new_password
  end

  private

  def notification_new_registration(username:,telegram_username:)
    if (support_chat_id = User.find_by(telegram_username: ENV['TELEGRAM_SUPPORT_USERNAME'])&.telegram_chat_id)
      text_user_info = <<~TEXT
        *Новая регистрация*
        Имя пользователя: `#{username}`
        Телеграм-аккаунт: `#{telegram_username}`
      TEXT

      bot.send_message chat_id: support_chat_id, text: text_user_info, parse_mode: 'Markdown'
    end
  end

  def clear_add_user
    session.delete(:new_password)
    session.delete(:new_username)
  end

  def telegram_fields
    {
      telegram_chat_id: from['id'],
      telegram_first_name: from['first_name'] || '',
      telegram_last_name: from['last_name'] || '',
      telegram_enabled: true,
      telegram_activated: true
    }
  end
end

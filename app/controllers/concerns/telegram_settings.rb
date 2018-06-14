# frozen_string_literal: true

module TelegramSettings

  def settings!(*args)
    case args&.join(' ')
    when button_cancel_title
      button_cancel_click
      return
    when button_change_language_title
      change_language
      return
    when button_change_password_title
      session.delete(:new_password)
      change_password
      return
    end

    markup = setup_button([[button_change_language_title, button_change_password_title],
                           [button_cancel_title]])

    respond_with :message, text: I18n.t(:selected_settings), reply_markup: markup
    save_context :settings!
  end

  def change_language(*args)
    respond = args&.join(' ')
    case respond
    when button_cancel_title
      button_cancel_click
      return
    when button_english_title, button_russian_title
      new_lang = respond == button_english_title ? :en : :ru

      text = I18n.t(:fail)
      if user.update(lang: new_lang)
        session[:lang] = new_lang
        set_locale
        text = I18n.t(:done, locale: new_lang)
      end

      respond_with :message, text: text, reply_markup: main_keyboard
      return
    end

    markup = setup_button([[button_english_title, button_russian_title],
                           [button_cancel_title]])

    respond_with :message, text: I18n.t(:selected_language), reply_markup: markup
    save_context :change_language
  end

  def change_password(*args)
    case args&.join(' ')
    when button_cancel_title
      button_cancel_click
      return
    when button_save_title

      text = user.update(password: session[:new_password]) \
        ? I18n.t(:done) \
        : I18n.t(:fail)

      respond_with :message, text: text, reply_markup: main_keyboard

      session.delete(:new_password)
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
    save_context :change_password
  end

  private

  def button_change_password_title
    "🛡 #{I18n.t(:change_password)}"
  end

  def button_change_language_title
    "‍🏳️‍🌈 #{I18n.t(:change_language)}"
  end

  def button_english_title
    "🏴󠁧󠁢󠁥󠁮󠁧󠁿 #{I18n.t(:english)}"
  end

  def button_russian_title
    "🇷🇺 #{I18n.t(:russian)}"
  end
end

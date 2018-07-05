# frozen_string_literal: true

module TelegramHelp

  APP_NAME = ENV['APP_NAME']

  def help!(*args)
    case args&.join(' ')
    when button_cancel_title
      button_cancel_click
      return
    when button_contacts_title
      support
      return
    when button_instructions_title
      instuctions
      return
    end

    markup = setup_button([[button_instructions_title, button_contacts_title],
                           [button_cancel_title]])

    respond_with :message, text: I18n.t(:help), reply_markup: markup
    save_context :help!
  end

  def instuctions
    respond_with :video, parse_mode: 'Markdown',
                 video: File.open('bot_assets/doc.mp4'),
                 caption: "*#{I18n.t(:instruction_registration)}*"

    respond_with :document, parse_mode: 'Markdown',
                 document: File.open('bot_assets/instruction.pdf'),
                 caption: "*#{I18n.t(:user_instruction)}*"
    save_context :help!
  end

  def support
    first_name = "☎️ #{I18n.t(:support)} #{APP_NAME}"
    phone_number = ENV['TELEGRAM_SUPPORT_PHONE']
    button_text = "#{I18n.t(:go_to)} #{APP_NAME}"
    url = ENV['WEB_URL'].gsub('localhost', '127.0.0.1')
    button = Telegram::Bot::Types::InlineKeyboardButton.new(text: button_text, url: url)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button]]).to_hash

    respond_with :contact, phone_number: phone_number, first_name: first_name, reply_markup: markup
    save_context :help!
  end

  private

  def button_contacts_title
    "☎️ #{I18n.t(:contacts)}"
  end

  def button_instructions_title
    "🖨 #{I18n.t(:instructions)}"
  end
end

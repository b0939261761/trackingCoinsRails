class PriceSendTelegramJob < ApplicationJob
  include SendgridMailer

  queue_as :notifications

  def perform(chat_id:, prices:)
    bot = Telegram::Bot::Client.new(ENV['TELEGRAM_BOT_TOKEN'])


    notification_id = 3

    text = 'test'

    url = ENV['WEB_URL'].gsub('localhost', '127.0.0.1')
    button = Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{I18n.t(:go_to)} Cryptonot", url: url)
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button]]).to_hash

    prices.each do |o|
      text = <<~TEXT
        *#{I18n.t(:pair)}*: `#{o[:currency]}`
        *#{I18n.t(:exchange)}*: `#{o[:exchange]}`
        *#{I18n.t(:direction)}*: `#{I18n.t(o[:direction])}`
        *#{I18n.t(:target_price)}*: `#{o[:price]}`
        *#{I18n.t(:current_price)}*: `#{o[:current_price]}`
        *±*: `#{o[:diff]}`
        *%*: `#{o[:percent]}`
      TEXT

      button_disable = Telegram::Bot::Types::InlineKeyboardButton.new(url: '',
        text: "🔕 #{I18n.t(:disable_notification)}", callback_data: "disable_notification:#{o[:notification_id]}")
      button_remove = Telegram::Bot::Types::InlineKeyboardButton.new(url: '',
        text: "🗑 #{I18n.t(:remove_notification)}", callback_data: "remove_notification:#{o[:notification_id]}")

      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[button_disable, button_remove]]).to_hash

      bot.send_message(chat_id: chat_id, text: text, parse_mode: 'Markdown', reply_markup: markup)
    end
  end
end

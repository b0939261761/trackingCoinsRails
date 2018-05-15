class PriceSendTelegramJob < ApplicationJob
  include SendgridMailer

  queue_as :notifications

  def perform(chat_id:, prices:)
    bot = Telegram::Bot::Client.new(ENV['TELEGRAM_BOT_TOKEN'])

    prices.each do |o|
      text = <<~TEXT
        #{I18n.t(:pair)}: #{o[:currency]}
        #{I18n.t(:exchange)}: #{o[:exchange]}
        #{I18n.t(:direction)}: #{I18n.t(o[:direction])}
        #{I18n.t(:target_price)}: #{o[:price]}
        #{I18n.t(:current_price)}: #{o[:current_price]}
        ±: #{o[:diff]}
        %: #{o[:percent]}
      TEXT

      bot.send_message(chat_id: chat_id, text: text)
    end
  end
end

# frozen_string_literal: true

# Access to site
module CheckNotifications

  def format_number(value, precision = 8)
    ActiveSupport::NumberHelper.number_to_rounded(value,
      delimiter: ' ', separator: '.', precision: precision, strip_insignificant_zeros: true)
  end

  def check_notifications
    sql = <<-SQL
      WITH
        get_notifications AS (
          UPDATE notifications SET
            sended = true
              WHERE NOT sended AND done AND activated
              RETURNING *
        )
      -- Результирующий запрос
      SELECT
        dd.email,
        cc.symbol as currency,
        bb.name AS exchange,
        aa.direction,
        aa.price,
        aa.current_price as current_price,
        dd.username,
        dd.lang,
        dd.email_enabled,
        dd.telegram_username,
        dd.telegram_chat_id,
        dd.telegram_activated,
        dd.telegram_enabled
      FROM get_notifications aa
      LEFT JOIN exchanges bb ON bb.id = aa.exchange_id
      LEFT JOIN pairs cc ON cc.id = aa.pair_id
      LEFT JOIN users dd ON dd.id = aa.user_id
      ORDER BY 1, 2, 3, 4, 5
    SQL

    result = JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json, symbolize_names: true)

    result
      .group_by { |o| o[:email] }
      .each do |email, data|
        lang = data[0][:lang]

        I18n.locale = lang

        prices = data.map do |o|
          current_price = o[:current_price].to_f
          price = o[:price].to_f
          {
            direction: o[:direction],
            current_price: format_number(current_price),
            price: format_number(price),
            diff: format_number(current_price - price),
            percent: format_number((current_price / price - 1) * 100, 3),
            currency: o[:currency],
            exchange: o[:exchange]
          }
        end

        if data[0][:email_enabled]
          PriceSendEmailJob.perform_later(email: email, lang: lang, prices: prices)
        end
        if data[0][:telegram_enabled] && data[0][:telegram_activated]
          chat_id = data[0][:telegram_chat_id]
          PriceSendTelegramJob.perform_later(chat_id: chat_id, prices: prices)
        end
      end
  end
end

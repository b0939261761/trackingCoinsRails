# frozen_string_literal: true

# Access to site
module CheckNotifications
  def check_notifications
    sql = <<-SQL
      WITH
        get_notifications AS (
          UPDATE notifications SET
            sended = true
              WHERE done AND activated
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
        dd.lang
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
        prices = data.map { |o| o.slice(:currency, :exchange, :direction, :price, :current_price) }
        lang = data[0][:lang]
        PriceSendJob.perform_later(email: email, lang: lang, prices: prices)
      end
  end
end

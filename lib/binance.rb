# frozen_string_literal: true

# Access to site
module Binance
  def binance
    url = URI('https://api.binance.com/api/v1/ticker/24hr')
    response = Net::HTTP.get(url)

    data = JSON.parse(response, symbolize_names: true)
    pairs = []
    prices = []
    data.each_with_index do |trade, index|
      symbol = trade[:symbol]
      pairs << "(( SELECT id FROM exchange ), '#{symbol}')"

      prices << "(( SELECT id FROM pairs_new WHERE symbol='#{symbol}' ), " \
                "#{trade[:lastPrice]}," \
                "'#{Time.at(trade[:closeTime].to_i/1000).to_s(:db)}')"
    end

    exchange_name = 'binance'

    sql = <<-SQL
      WITH
        -- Получаем обменник
        exchange AS (
          SELECT id, name FROM exchanges
          WHERE name = '#{exchange_name}'
          LIMIT 1
        ),

        -- Добавляем пары
        pairs_new AS (
          INSERT INTO pairs (
            exchange_id,
            symbol
          )
            VALUES
              #{pairs.join(',')}
            ON CONFLICT ( exchange_id, symbol )
              DO UPDATE SET symbol = EXCLUDED.symbol
            RETURNING id, exchange_id, symbol
        ),
        -- Добавляем цены
        prices_new AS (
          INSERT INTO prices (
            pair_id,
            price,
            close_time
          )
            VALUES
              #{prices.join(',')}
            ON CONFLICT ( pair_id, close_time )
              DO UPDATE SET price = EXCLUDED.price
            RETURNING id, pair_id, price
        )
       -- Сохраняем цену
      UPDATE notifications SET
        current_price = aa.price,
        sended = CASE
          WHEN
            ( direction = 'above' AND current_price < notifications.price AND sended ) OR
 	          ( direction = 'less' AND current_price > notifications.price AND sended ) THEN false
          ELSE sended
          END,
        done = CASE
          WHEN
            ( direction = 'above' AND current_price >= notifications.price AND NOT sended AND activated ) OR
            ( direction = 'less' AND current_price <= notifications.price AND NOT sended AND activated ) THEN true
          ELSE false
          END
        FROM prices_new aa
        WHERE aa.pair_id = notifications.pair_id AND activated
    SQL

    # -- Результирующий запрос
    # SELECT aa.id AS exchange_id,
    #       aa.name AS exchange_name,
    #       bb.id AS pairs_id,
    #       bb.symbol,
    #       cc.id AS price_id,
    #       cc.price
    #   FROM exchange aa
    #   LEFT JOIN pairs_new bb ON aa.id = bb.exchange_id
    #   LEFT JOIN prices_new cc ON bb.id = cc.pair_id
    #   LEFT JOIN notifications dd ON aa.id = dd.exchange_id
    #       AND bb.id = dd.pair_id

    JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json, symbolize_names: true)

  end
end

# frozen_string_literal: true

# Access to site
module Livecoin
  def livecoin
    url = URI('https://api.livecoin.net/exchange/ticker')
    response = Net::HTTP.get(url)

    data = JSON.parse(response, symbolize_names: true)
    pairs = []
    prices = []

    data.each do |trade|
      symbol = trade[:symbol]

      pairs << "(( SELECT id FROM exchange ), '#{symbol}')"

      prices << <<-SQL.squish
        (( SELECT id FROM pairs_new WHERE symbol='#{symbol}' ),
        #{trade[:last]},
        '#{Time.new}')
        SQL
    end

    exchange_name = 'Livecoin'

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
      UPDATE notifications AS aa SET
        current_price = bb.price,
        sended = CASE
          WHEN
            (direction = 'above' AND bb.price < aa.price) OR
 	          (direction = 'less' AND bb.price > aa.price) THEN false
          ELSE sended
          END,
        done = CASE
          WHEN
            NOT sended AND activated AND
            (( direction = 'above' AND bb.price >= aa.price ) OR
            ( direction = 'less' AND bb.price <= aa.price )) THEN true
          ELSE false
          END
        FROM prices_new bb
        WHERE aa.pair_id = bb.pair_id AND activated
    SQL

    JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json, symbolize_names: true)
  end
end

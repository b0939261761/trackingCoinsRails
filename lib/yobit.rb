# frozen_string_literal: true

# Access to site
module Yobit
  YOBIT_NAME = 'YObit'
  YOBIT_URL_PAIRS = URI('https://yobit.net/api/3/info')
  YOBIT_URL_PRICES = 'https://yobit.net/api/3/ticker1111/'

  def yobit_pairs
    response_pairs = Net::HTTP.get(YOBIT_URL_PAIRS)
    data_pairs = JSON.parse(response_pairs, symbolize_names: true)

    pairs = data_pairs[ :pairs ].map { |o| sql_pairs(symbol: o.first.to_s.upcase.sub('_', '/')) }
    yobit_insert_pairs(exchange_name: YOBIT_NAME, pairs: pairs)
  end

  def yobit
    data_pairs = JSON.parse(Notification
      .joins(:pair, :exchange)
      .select('DISTINCT pairs.symbol')
      .where(exchanges: { name: YOBIT_NAME}).to_json,
       symbolize_names: true)

    p data_pairs
    data_pairs.each_slice(45) do |pairs_info|
      sleep 1

      pairs_list = pairs_info.map{ |o| o[:symbol].downcase.sub('/', '_') }.join('-')

      url_prices = URI("#{YOBIT_URL_PRICES}/#{pairs_list}")
      response_prices = Net::HTTP.get(url_prices)
      data_prices = JSON.parse(response_prices, symbolize_names: true)

      prices = []

      data_prices.each do | pair, pair_info |
        symbol = pair.to_s.upcase.sub('_', '/')
        close_time = Time.at(pair_info[:updated].to_i).to_s(:db)
        price = pair_info[:last]

        prices << youbit_sql_prices(symbol:symbol, exchange_name: YOBIT_NAME, price: price, close_time: close_time)
      end

      youbit_insert_prices(prices: prices)
    end
  end

  def youbit_sql_prices(symbol:, exchange_name:, price:, close_time:)
    <<-SQL.squish
      ((SELECT id FROM pairs
        WHERE
          symbol='#{symbol}'
          AND
          exchange_id=(SELECT id FROM exchanges WHERE name = '#{exchange_name}' LIMIT 1)
      ),
      #{price},
      '#{close_time}')
    SQL
  end

  def youbit_insert_prices(prices:)
    sql = <<-SQL
      WITH
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


  def yobit_insert_pairs(exchange_name:, pairs:)
    sql = <<-SQL
      WITH
        -- Получаем обменник
        exchange AS (
          SELECT id, name FROM exchanges
          WHERE name = '#{exchange_name}'
          LIMIT 1
        )

        INSERT INTO pairs (
          exchange_id,
          symbol
        )
          VALUES
            #{pairs.join(',')}
          ON CONFLICT ( exchange_id, symbol )
            DO UPDATE SET symbol = EXCLUDED.symbol
        RETURNING id, exchange_id, symbol
      SQL

    JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json, symbolize_names: true)
  end
end

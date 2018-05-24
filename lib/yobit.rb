# frozen_string_literal: true

# Access to site
module Yobit
  def yobit
    url_pairs = URI('https://yobit.net/api/3/info')
    response_pairs = Net::HTTP.get(url_pairs)
    data_pairs = JSON.parse(response_pairs, symbolize_names: true)

    pairs = []
    prices = []

    data_pairs[ :pairs ].each_slice(45) do |pairs_piece|
      sleep 1

      pairs_list = pairs_piece.map(&:first).join('-')
      url_prices = URI("https://yobit.net/api/3/ticker/#{pairs_list}")
      response_prices = Net::HTTP.get(url_prices)
      data_prices = JSON.parse(response_prices, symbolize_names: true)

      data_prices.each do | pair, pair_data |
        symbol = pair.to_s.upcase.sub('_', '/')

        pairs << "(( SELECT id FROM exchange ), '#{symbol}')"

        prices << <<-SQL.squish
          (( SELECT id FROM pairs_new WHERE symbol='#{symbol}' ),
            #{pair_data[:last]},
            '#{Time.at(pair_data[:updated].to_i).to_s(:db)}')
          SQL
      end
    end

    exchange_name = 'YObit'

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

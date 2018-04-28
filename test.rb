require 'json'

response = JSON.parse( File.read('binare.txt') )

pairs = []
prices = []
response.each_with_index do | trade, index |
  symbol = trade['symbol']
  pairs << "(( SELECT id FROM exchange ), '#{symbol}')"

  prices << "(( SELECT id FROM pairs_new WHERE symbol='#{symbol}' ), " +
            "#{trade['lastPrice']}," +
            "'#{ Time.at(trade['close_time'].to_i/1000).to_s(:db) }')"
  break if index == 2
end


exchange_name = 'binare'

sql = <<-SQL
  WITH
    -- Получаем обменник
    exchange AS (
      SELECT id, name FROM exchanges
      WHERE name = '#{ exchange_name }'
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
  -- Результирующий запрос
  SELECT aa.id AS exchange_id,
         aa.name AS exchange_name,
         bb.id AS pairs_id,
         bb.symbol,
         cc.id AS price_id,
         cc.price
    FROM exchange aa
    LEFT JOIN pairs_new bb ON aa.id = bb.exchange_id
    LEFT JOIN prices_new cc ON bb.id = cc.pair_id
SQL



result = JSON.parse( ActiveRecord::Base.connection.execute( sql ).to_json, symbolize_names: true )

puts result





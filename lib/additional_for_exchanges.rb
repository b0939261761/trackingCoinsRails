# frozen_string_literal: true

# Access to site
module AdditionalForExchanges
  def sql_pairs(symbol:)
    "(( SELECT id FROM exchange ), '#{symbol}')"
  end

  def sql_prices(symbol:,price:,close_time:)
    <<-SQL.squish
      (( SELECT id FROM pairs_new WHERE symbol='#{symbol}' ),
      #{price},
      '#{close_time}')
    SQL
  end

  def insert_into_db(exchange_name:, pairs:, prices:)
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

  def currencies
    @currencies ||= JSON.parse(Currency.select( :id, :symbol ).order( :symbol ).to_json, symbolize_names: true)
  end

  def compare_currencies(currency:)
    if currency
      all_compare = currencies.select { |o| currency.include?(o[:symbol]) }

      all_compare.each do |obj_first|
        first = obj_first[:symbol]

        all_compare.each do |second|
          second = second[:symbol]

          if first + second == currency
            return "#{first}/#{second}"
          end
        end
      end
    end

    return currency
  end
end

# frozen_string_literal: true

module NotificationsAdditional

  private

  def notifications_sql_value(args)
    <<-SQL.squish
      (
        #{args[:user_id]},
        #{args[:exchange_id]},
        (SELECT id FROM pairs WHERE symbol = '#{args[:symbol]}' AND exchange_id = #{args[:exchange_id]}),
        '#{args[:direction]}',
        #{args[:price]},
        #{args[:activated]}
      )
    SQL
  end

  def exchanges_by_pair(symbol:)
    Exchange
      .joins(:pairs)
      .select(:id, :name)
      .where(pairs: {symbol: symbol})
      .order(:name)
  end

  def notifications_sql_insert(values:, ids:)
    ids = ids.any? ? ids : [0]

    sql = if ids.length
      <<-SQL
        WITH
          notifications_del AS (
            DELETE FROM notifications aa
              USING (
                SELECT id
                  FROM UNNEST( ARRAY #{ids} ) AS id
              ) bb
              WHERE aa.id = bb.id
          )
      SQL
    end

    sql += <<-SQL
      INSERT INTO notifications (
        user_id,
        exchange_id,
        pair_id,
        direction,
        price,
        activated
      )
        VALUES
          #{values.join(',')}
        ON CONFLICT ( user_id, pair_id, direction, price )
          DO UPDATE SET
            direction = EXCLUDED.direction,
            activated = EXCLUDED.activated,
            sended = false
    SQL


    JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json, symbolize_names: true)
  end

end

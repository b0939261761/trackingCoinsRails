# frozen_string_literal: true

module Notifications

  def get_exchanges
    symbol = params[:symbol]
    exchanges = Exchange
      .joins(:pairs)
      .select(:id, :name)
      .where(pairs: {symbol: symbol})
      .order(:name)

    render json: { exchanges: exchanges}
  end

  def get_pairs
    render json: { pairs: Pair.select(:symbol).distinct.order(:symbol).pluck(:symbol) }
  end

  def edit_notification
    par = params.permit(:symbol, :direction, :price, :activated)

    values = []
    params[:exchange_ids].each { |id| values << notifications_sql_value(par.merge(exchange_id: id))}

    notifications_sql_insert(values: values, ids: params[:ids])

    render json: { notifications: notifications(user_id: user_id) }
  end

  def remove_notification
    Notification.where(id: params[:ids]).delete_all
    render json: { notifications: notifications(user_id: user_id) }
  end

  def get_notifications
    render json: { notifications: notifications(user_id: user_id) }
  end

  private

  def notifications(user_id:)
    notifications = Notification
      .joins( :exchange, :pair )
      .select(
        :id,
        :exchange_id,
        'exchanges.name AS exchange_name',
        'pairs.symbol',
        :direction,
        :price,
        :activated
      )
      .where(user_id: user_id)
      .order( 'pairs.symbol', :direction, :price, 'exchange_name' )

    result = []

    notifications
      .group_by{ |o| { symbol: o[:symbol], price: o[:price], direction: o[:direction], activated: o[:activated] } }
      .each do |k,v|

        ids = []
        exchange_ids = []
        exchange_names = []

        v.each do |exchange|
          ids << exchange[:id]
          exchange_ids << exchange[:exchange_id]
          exchange_names << exchange[:exchange_name]
        end

        result << k.merge({ids: ids, exchange_ids: exchange_ids, exchange_names: exchange_names})
      end

    result
  end

  def notifications_sql_value(args)
    <<-SQL.squish
      (
        #{user_id},
        #{args[:exchange_id]},
        (SELECT id FROM pairs WHERE symbol = '#{args[:symbol]}' AND exchange_id = #{args[:exchange_id]}),
        '#{args[:direction]}',
        #{args[:price]},
        #{args[:activated]}
      )
    SQL
  end

  def notifications_sql_insert(values:, ids:)

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

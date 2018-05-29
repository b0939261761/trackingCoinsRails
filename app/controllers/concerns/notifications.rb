# frozen_string_literal: true

module Notifications
  def get_exchanges
    render json: { exchanges: Exchange.select(:id, :name) }
  end

  def get_pairs
    render json: { pairs: Pair.select(:id, :symbol).where(exchange_id: params[:exchange_id])}
  end

  # def get_exchanges
  #   # symbol = params[:symbol]
  #   symbol = 'BTC/USD'
  #   exchanges = Exchange
  #     .joins(:pairs)
  #     .select(:id, :name)
  #     .where(pairs: {symbol: symbol})

  #   render json: { exchanges: exchanges}
  # end

  # def get_pairs
  #   render json: { pairs: Pair.select(:id, :symbol).where(exchange_id: params[:exchange_id])}
  # end

  def edit_notification
    if (id = params[:id].nonzero?)
      par = params.permit(:exchange_id, :pair_id, :direction, :price, :activated)
      notification = Notification.find_by(id: id, user_id: user_id)
      notification.destroy unless notification.update(par.merge(sended: false))
    else
      sql = <<-SQL
        INSERT INTO notifications (
            user_id,
            exchange_id,
            pair_id,
            direction,
            price,
            activated
          )
            VALUES (
              #{user_id},
              #{params['exchange_id']},
              #{params['pair_id']},
              '#{params['direction']}',
              #{params['price']},
              #{params['activated']}
            )
            ON CONFLICT ( user_id, pair_id, direction, price )
              DO UPDATE SET
                direction = EXCLUDED.direction,
                activated = EXCLUDED.activated,
                sended = false
      SQL
      ActiveRecord::Base.connection.execute( sql )
    end

    render json: { notifications: notifications(user_id: user_id) }
  end

  def remove_notification
    if (id = params[:id].nonzero?)
      Notification.find_by(id: id, user_id: user_id).destroy
    end
    render json: { notifications: notifications(user_id: user_id) }
  end

  def get_notifications
    render json: { notifications: notifications(user_id: user_id) }
  end

  private

  def notifications(user_id:)
    Notification
      .joins( :exchange, :pair )
      .select(
        :id,
        :exchange_id,
        'exchanges.name AS exchange_name',
        :pair_id,
        'pairs.symbol',
        :direction,
        :price,
        :activated
      )
      .where(user_id: user_id)
  end
end

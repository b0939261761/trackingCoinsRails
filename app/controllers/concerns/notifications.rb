# frozen_string_literal: true

#
module Notifications
  def get_exchanges
    render json: {status: true, exchanges: Exchange.select(:id, :name)}
  end

  def get_pairs
    render json: {status: true, pairs: Pair.select(:id, :symbol).where(exchange_id: params[:exchange_id])}
  end

  def edit_notification
    token = decode_token(bearer_token)

    render json:
      if token && token['type'] == 'access'
        user_id = token['user']

        if ( id = params[:id].nonzero? )
          par = params.permit(:exchange_id, :pair_id, :direction, :price, :activated)
          notification = Notification.find_by(id: id, user_id: user_id)
          notification.destroy unless notification.update(par)

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
                    activated = EXCLUDED.activated
          SQL
          ActiveRecord::Base.connection.execute( sql )
        end

        { status: true, notifications: notifications(user_id: user_id) }
      else
        { status: false }
      end
  end

  def remove_notification
    token = decode_token(bearer_token)

    render json:
      if token && token['type'] == 'access'
        user_id = token['user']

        if ( id = params[:id].nonzero? )
          Notification.find_by(id: id, user_id: user_id).destroy
        end
          { status: true, notifications: notifications(user_id: user_id) }
      else
        { status: false }
      end
  end

  def get_notifications
    token = decode_token(bearer_token)
    render json:
      if token && token['type'] == 'access'
        { status: true, notifications: notifications(user_id: token['user']) }
      else
        { status: false }
      end
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

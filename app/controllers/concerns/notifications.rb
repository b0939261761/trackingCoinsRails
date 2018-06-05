# frozen_string_literal: true

module Notifications
  include NotificationsAdditional

  def get_exchanges
    render json: { exchanges: exchanges_by_pair(symbol: params[:symbol])}
  end

  def get_pairs
    render json: { pairs: Pair.select(:symbol).distinct.order(:symbol).pluck(:symbol) }
  end

  def edit_notification
    par = params.permit(:symbol, :direction, :price, :activated)

    values = []
    params[:exchange_ids].each do |id| 
      values << notifications_sql_value(par.merge(user_id: user_id, exchange_id: id))
    end

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
end

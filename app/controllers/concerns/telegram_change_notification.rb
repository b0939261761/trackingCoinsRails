# frozen_string_literal: true

module TelegramChangeNotification

  def enable_notification_callback_query(notification_id, *)
    notification_turn(notification_id: notification_id, activated: true)
  end

  def disable_notification_callback_query(notification_id, *)
    notification_turn(notification_id: notification_id, activated: false)
  end

  def remove_notification_callback_query(notification_id, *)
    if Notification.where(id: notification_id).delete_all
      buttons = [button_create_notification]
    else
      answer_callback_query(I18n.t(:error))
      return
    end

    edit_message :reply_markup, reply_markup: setup_inline_button([buttons])
    answer_callback_query(I18n.t(:done))
  end

  def create_notification_callback_query(*)
    data = payload['message']['text'].scan(/(?<=:).+(?=\s*$)/).map(&:strip)

    sql_exchanges = "(SELECT id FROM exchanges WHERE name = '#{data[1]}' LIMIT 1)"

    direction = [I18n.t(:less, locale: :ru), I18n.t(:less, locale: :en)].include?(data[2]) \
      ? :less
      : :above

    message_text = I18n.t(:done)

    sql = <<-SQL
      INSERT INTO notifications (
        user_id,
        exchange_id,
        pair_id,
        direction,
        price,
        activated
      )
        VALUES(
          #{session[:user_id]},
          #{sql_exchanges},
          (SELECT id FROM pairs
            WHERE symbol = '#{data[0]}' AND exchange_id = #{sql_exchanges}
            LIMIT 1),
          '#{direction}',
          #{data[3]},
          true
        )
        ON CONFLICT ( user_id, pair_id, direction, price )
          DO UPDATE SET
            direction = EXCLUDED.direction,
            activated = EXCLUDED.activated,
            sended = false
        RETURNING id
    SQL

    notification = JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json, symbolize_names: true)
    if notification.any?
      notification_id = notification[0][:id]
      buttons = [button_disable_notification(notification_id: notification_id),
                button_remove_notification(notification_id: notification_id)]
      edit_message :reply_markup, reply_markup: setup_inline_button([buttons])
    else
      message_text = I18n.t(:error)
    end

    answer_callback_query(message_text)
  end

  private

  def notification_turn(notification_id:, activated:)
    if (notification = Notification.find_by(id: notification_id))
      if notification.update(activated: activated)
        button_activated = notification.activated \
          ? button_disable_notification(notification_id: notification_id)
          : button_enable_notification(notification_id: notification_id)

        buttons = [ button_activated, button_remove_notification(notification_id: notification_id)]
      else
        answer_callback_query(I18n.t(:error))
        return
      end
    else
      buttons = [button_create_notification]
    end

    edit_message :reply_markup, reply_markup: setup_inline_button([buttons])
    answer_callback_query(I18n.t(:done))
  end

  def setup_inline_button(buttons)
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons).to_hash
  end

  def button_disable_notification(notification_id:)
    Telegram::Bot::Types::InlineKeyboardButton.new(url: '',
      text: "🔕 #{I18n.t(:disable_notification)}",
      callback_data: "disable_notification:#{notification_id}")
  end

  def button_remove_notification(notification_id:)
    Telegram::Bot::Types::InlineKeyboardButton.new(url: '',
      text: "🗑 #{I18n.t(:remove_notification)}",
      callback_data: "remove_notification:#{notification_id}")
  end

  def button_enable_notification(notification_id:)
    Telegram::Bot::Types::InlineKeyboardButton.new(url: '',
      text: "🔔 #{I18n.t(:enable_notification)}",
      callback_data: "enable_notification:#{notification_id}")
  end

  def button_create_notification
    Telegram::Bot::Types::InlineKeyboardButton.new(url: '',
      text: "➕ #{I18n.t(:create_notification)}",
      callback_data: "create_notification:")
  end
end

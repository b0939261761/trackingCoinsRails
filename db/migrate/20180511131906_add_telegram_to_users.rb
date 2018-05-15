class AddTelegramToUsers < ActiveRecord::Migration[5.2]
  def change
    table_name = :users

    change_table table_name do |t|
      t.boolean :email_enabled, default: true, null: false, comment: 'Отправлять уведомления на email'

      t.string :telegram_username, limit: 32, default: '', null: false, comment: 'Пользователь в Telegram'
      t.string :telegram_first_name, limit: 255, default: '', null: false, comment: 'Имя в Telegram'
      t.string :telegram_last_name, limit: 255, default: '', null: false, comment: 'Фамилия в Telegram'
      t.integer :telegram_chat_id, default: 0, null: false, comment: 'Id чата в Telegram'
      t.boolean :telegram_enabled, default: true, null: false, comment: 'Отправлять уведомления на telegram'
      t.boolean :telegram_activated, default: true, null: false, comment: 'Активирован telegram'

      t.index :telegram_username
    end

  end
end

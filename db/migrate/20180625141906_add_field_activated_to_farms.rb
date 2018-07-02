class AddFieldActivatedToFarms < ActiveRecord::Migration[5.2]
  def change
    table_name = :farms
    add_column table_name, :activated, :boolean, default: true, null: false, comment: 'Активирован'
    t.integer :telegram_chat_id, default: 0, null: false, comment: 'Id чата в Telegram'

  end
end

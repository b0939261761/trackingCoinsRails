class AddUniqueIndexChatIdToUsers < ActiveRecord::Migration[5.2]
  def change
    table_name = :users

    change_column_null table_name, :telegram_chat_id, :true
    change_column_default table_name, :telegram_chat_id, from: 0, to: nil

    reversible do |direction|
      direction.up do
        execute <<-SQL.squish
          UPDATE #{table_name} aa SET telegram_chat_id = NULL
        SQL
      end
    end

    add_index table_name, :telegram_chat_id, unique: true
  end
end

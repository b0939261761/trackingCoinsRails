class AddUniqueIndexChatIdToUsers < ActiveRecord::Migration[5.2]
  def change
    table_name = :users

    change_column_null table_name, :telegram_chat_id, :true
    change_column_default table_name, :telegram_chat_id, nil

    # reversible do |direction|
    #   direction.up do
    #     execute <<-SQL.squish
    #       UPDATE #{table_name} aa SET telegram_chat_id =
    #         FROM monitoring_accounts bb WHERE aa.user_id = bb.user_id AND bb.user_id IS NOT NULL;
    #       DELETE FROM #{table_name} WHERE monitoring_account_id IS NULL
    #     SQL
    #   end
    # end



    add_index table_name, :telegram_chat_id, unique: true
  end
end

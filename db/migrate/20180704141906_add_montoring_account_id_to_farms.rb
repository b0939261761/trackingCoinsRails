class AddMontoringAccountIdToFarms < ActiveRecord::Migration[5.2]
  def change
    table_name = :farms

    add_reference table_name, :monitoring_account, foreign_key: { on_delete: :cascade }, comment: 'Кошелек для мониторинга'

    reversible do |direction|
      direction.up do
        execute <<-SQL.squish
          UPDATE #{table_name} aa SET monitoring_account_id = bb.id
            FROM monitoring_accounts bb WHERE aa.user_id = bb.user_id AND bb.user_id IS NOT NULL;
          DELETE FROM #{table_name} WHERE monitoring_account_id IS NULL
        SQL
      end
    end

    change_column_null table_name, :monitoring_account_id, :false
  end
end

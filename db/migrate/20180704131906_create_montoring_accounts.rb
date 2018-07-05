class CreateMontoringAccounts < ActiveRecord::Migration[5.2]
  def change
    table_name = :monitoring_accounts

    create_table table_name, comment: 'Кошельки мониторинга' do |t|
      t.belongs_to :user, foreign_key: { on_delete: :cascade }, null: false, comment: 'Пользователи'
      t.string :account, limmit: 70, default: '', null: false, comment: 'Кошелек'

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата создания записи'
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата обновления записи'

      t.index [:user_id, :account], unique: true
    end

    change_column_comment(table_name, :id, 'Уникальный идентификатор')

    reversible do |direction|
      direction.up do
        execute <<-SQL.squish
          CREATE TRIGGER #{table_name}_update_at
            BEFORE UPDATE ON #{table_name}
              FOR EACH ROW EXECUTE PROCEDURE update_at_timestamp();

            INSERT INTO #{table_name} (user_id, account)
              SELECT id, nanopool_address FROM users WHERE nanopool_address != ''
        SQL
      end
    end
  end
end

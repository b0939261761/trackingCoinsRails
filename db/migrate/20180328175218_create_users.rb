class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    table_name = :users

    create_table table_name, comment: 'Пользователи' do |t|
      t.string :username, limit: 30, default: '', null: false, comment: 'Имя пользователя'
      t.string :email, limit: 100, default: '', null: false, comment: 'Почта'
      t.string :password_digest, limit: 60, default: '', null: false, comment: 'Зашифрованный пароль'
      t.string :refresh_token, limit: 124, default: '', null: false, comment: 'Refresh-токен'
      t.boolean :confirmed, default: false, null: false, comment: 'Подтверждение регистрации'

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата создания записи'
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата обновления записи'

      t.index :email, unique: true
    end

    change_column_comment(table_name, :id, 'Уникальный идентификатор')

    reversible do |direction|
      direction.up do
        execute <<-SQL.squish
          CREATE TRIGGER #{table_name}_update_at
            BEFORE UPDATE ON #{table_name}
              FOR EACH ROW EXECUTE PROCEDURE update_at_timestamp()
        SQL
      end
    end
  end
end

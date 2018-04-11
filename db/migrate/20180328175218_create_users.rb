class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    table_name = :users

    create_table table_name, comment: 'Пользователи' do |t|
      t.string :username, default: '', null: false, comment: 'Имя пользователя'
      t.string :email, default: '', null: false, comment: 'Почта'
      t.string :password_digest, default: '', null: false, comment: 'Зашифрованный пароль'
      t.string :refresh_token, :string, default: '', null: false, comment: 'Refresh-токен'
      t.boolean :confirmed, :boolean, default: false, null: false, comment: 'Подтверждение регистрации'

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

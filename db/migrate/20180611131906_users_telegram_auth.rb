class UsersTelegramAuth < ActiveRecord::Migration[5.2]
  def change
    table_name = :users

    add_column table_name, :email_activated, :boolean, default: false, null: false, comment: 'Активирован email'

    change_column_default table_name, :email, from: '', to: nil
    change_column_default table_name, :email_enabled, from: true, to: false
    change_column_null table_name, :email, true

    change_column_default table_name, :telegram_username, from: '', to: nil
    change_column_default table_name, :telegram_enabled, from: true, to: false

    remove_column table_name, :confirmed

    reversible do |direction|
      change_column_null table_name, :telegram_username, true

      direction.up do
        execute <<-SQL.squish
          UPDATE #{table_name}
            SET telegram_username = NULL
            WHERE telegram_username = ''
        SQL

        execute <<-SQL.squish
          UPDATE #{table_name}
            SET email_activated = true
        SQL
      end

      direction.down do
        execute <<-SQL.squish
          UPDATE #{table_name}
            SET telegram_username = ''
            WHERE telegram_username IS NULL
        SQL

        change_column_null table_name, :telegram_username, false
      end
    end

    remove_index table_name, :telegram_username
    add_index table_name, :telegram_username, unique: true
  end
end

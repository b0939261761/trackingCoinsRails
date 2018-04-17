class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    reversible do |direction|
      direction.up do
        execute <<-SQL.squish
          CREATE TYPE e_direction AS ENUM ('less', 'above');
        SQL
      end

      direction.down do
        execute <<-SQL.squish
          DROP TYPE e_direction
        SQL
      end

    end

    table_name = :notifications

    create_table table_name, comment: 'Уведомление' do |t|
      t.belongs_to :user, foreign_key: { on_delete: :cascade }, null: false, comment: 'Пользователь'
      t.belongs_to :exchange, foreign_key: { on_delete: :cascade }, null: false, comment: 'Биржа'
      t.belongs_to :pair, foreign_key: { on_delete: :cascade }, null: false, comment: 'Валютная пара'
      t.column :direction, :e_direction, default: 'above', null: false, comment: 'Направление'
      t.decimal :price, precision: 18, scale: 8, default: 0, null: false, comment: 'Цена'
      t.boolean :activated, null: false, default: true, comment: 'Активный'

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата создания записи'
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата обновления записи'

      t.index %i(user_id pair_id direction price), name: 'notifications_user_pair_direction_price', unique: true
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

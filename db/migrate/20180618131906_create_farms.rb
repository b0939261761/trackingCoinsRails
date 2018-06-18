class CreateFarms < ActiveRecord::Migration[5.2]
  def change
    table_name = :farms

    create_table table_name, comment: 'Фермы для мониторинга' do |t|
      t.belongs_to :user, foreign_key: { on_delete: :cascade }, null: false, comment: 'Пользователи'

      t.string :name, limit: 50, default: '', null: false, comment: 'Нименование фермы'
      t.decimal :sum_hashrate, precision: 8, scale: 3, default: 0, null: false, comment: 'Сумма хешрейтов'
      t.decimal :amount, precision: 8, scale: 3, default: 0, null: false, comment: 'Количество проверок'

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата создания записи'
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата обновления записи'

      t.index [:user_id, :name], unique: true
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

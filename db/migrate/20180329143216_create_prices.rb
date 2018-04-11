class CreatePrices < ActiveRecord::Migration[5.1]
  def change
    table_name = :prices

    create_table table_name, comment: 'Котировки' do |t|
      t.belongs_to :pair, foreign_key: { on_delete: :cascade }, null: false, comment: 'Валюная пара'
      t.decimal :price, precision: 18, scale: 8, default: 0, null: false, comment: 'Цена'
      t.datetime :close_time, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата сделки'

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата создания записи'
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата обновления записи'

      t.index %i(pair_id close_time), unique: true
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


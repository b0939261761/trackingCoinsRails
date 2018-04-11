# frozen_string_literal: true

class CreatePairs < ActiveRecord::Migration[5.1]
  def change
    table_name = :pairs

    create_table table_name, comment: 'Валютные пары' do |t|
      t.belongs_to :exchange, foreign_key: { on_delete: :cascade }, null: false, comment: 'Биржи'
      t.string :symbol, default: '', null: false, comment: 'Символ валют'

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата создания записи'
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата обновления записи'

      t.index [ :exchange_id, :symbol ], unique: true
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

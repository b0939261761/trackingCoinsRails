class CreateCurrencies < ActiveRecord::Migration[5.2]
  def change
    table_name = :currencies

    create_table table_name, comment: 'Справочник валют' do |t|
      t.string :symbol, limit: 10, default: '', null: false, comment: 'Символ валюты'
      t.string :name, limit: 50, default: '', null: false, comment: 'Нименование валюты'
      t.string :slug, limit: 50, default: '', null: false, comment: 'Слаг валюты'

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата создания записи'
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }, comment: 'Дата обновления записи'

      t.index :symbol, unique: true
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

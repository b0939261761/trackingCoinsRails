class DelFieldsToMonitoring < ActiveRecord::Migration[5.2]
  def change
    remove_reference :farms, :user, foreign_key: { on_delete: :cascade }, comment: 'Пользователи'
    remove_column :users, :nanopool_address, :string, limmit: 70, default: '', null: false, comment: 'Nanopool Адрес кошелька'
  end
end

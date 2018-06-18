class AddFieldLastHashrateToFarms < ActiveRecord::Migration[5.2]
  def change
    table_name = :farms

    add_column table_name, :last_hashrate, :decimal, precision: 8, scale: 3, default: 0, null: false, comment: 'Последний хешрейт'
    change_column table_name, :sum_hashrate, :decimal, precision: 18, scale: 3
  end
end

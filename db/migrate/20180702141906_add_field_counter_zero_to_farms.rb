class AddFieldCounterZeroToFarms < ActiveRecord::Migration[5.2]
  def change
    table_name = :farms

    reversible do |dir|
      dir.up { change_column table_name, :amount, :integer }
      dir.down { change_column table_name, :amount, :decimal, precision: 8, scale: 3 }
    end

    add_column table_name, :counter_zero, :integer, default: 0, null: false, comment: 'Счетчик для количества подряд неработатающей фермы'
  end
end

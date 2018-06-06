class ChangeFieldPrices < ActiveRecord::Migration[5.2]
  def change
    change_column :prices, :price, :decimal, precision: 20, scale: 10
    change_column :notifications, :price, :decimal, precision: 20, scale: 10
    change_column :notifications, :current_price, :decimal, precision: 20, scale: 10
  end
end

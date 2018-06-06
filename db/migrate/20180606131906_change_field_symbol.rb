class ChangeFieldSymbol < ActiveRecord::Migration[5.2]
  def change
    change_column :currencies, :symbol, :string, limit: 15
    change_column :pairs, :symbol, :string, limit: 15
  end
end

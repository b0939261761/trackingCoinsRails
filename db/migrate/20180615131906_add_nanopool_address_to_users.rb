class AddNanopoolAddressToUsers < ActiveRecord::Migration[5.2]
  def change
    table_name = :users
    add_column table_name, :nanopool_address, :string, limmit: 70, default: '', null: false, comment: 'Nanopool Адрес кошелька'
  end
end

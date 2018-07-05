class AddUniqueIndexToFarms < ActiveRecord::Migration[5.2]
  def change
    table_name = :farms
    add_index table_name, [:monitoring_account_id, :name], unique: true
  end
end

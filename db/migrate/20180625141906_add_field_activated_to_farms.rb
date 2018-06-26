class AddFieldActivatedToFarms < ActiveRecord::Migration[5.2]
  def change
    table_name = :farms
    add_column table_name, :activated, :boolean, default: true, null: false, comment: 'Активирован'
  end
end

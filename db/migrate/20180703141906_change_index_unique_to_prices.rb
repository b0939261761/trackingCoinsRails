class ChangeIndexUniqueToPrices < ActiveRecord::Migration[5.2]
  def change
    table_name = :prices

    reversible do |direction|
      direction.up { execute "TRUNCATE #{table_name}" }
    end

    remove_index table_name, column: %i(pair_id close_time), unique: true
    add_index table_name, :pair_id, name: :index_prices_on_pair_id_uniq, unique: true
  end
end

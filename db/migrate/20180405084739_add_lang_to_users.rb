class AddLangToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :lang, :string, limit: 2, default: 'en', null: false, comment: 'Активный язык'
  end
end

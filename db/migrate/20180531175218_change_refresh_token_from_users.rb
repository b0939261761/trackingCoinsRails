class ChangeRefreshTokenFromUsers < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :refresh_token, :string, limit: 130
  end
end

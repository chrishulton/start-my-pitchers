class AddAuthFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :yahoo_id, :string
    add_column :users, :yahoo_token, :string
    add_column :users, :yahoo_secret, :string
  end
end

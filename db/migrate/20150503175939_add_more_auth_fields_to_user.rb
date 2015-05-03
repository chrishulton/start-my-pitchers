class AddMoreAuthFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :yahoo_session_handle, :string
  end
end

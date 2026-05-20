class AddAppColumnsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :snack_cost_in_coins, :integer, default: 10, null: false
  end
end

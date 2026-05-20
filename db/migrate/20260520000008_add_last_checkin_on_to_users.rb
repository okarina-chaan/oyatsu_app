class AddLastCheckinOnToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_checkin_on, :date
  end
end

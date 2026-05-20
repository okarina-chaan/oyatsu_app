class CreateSnacks < ActiveRecord::Migration[8.0]
  def change
    create_table :snacks do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name, null: false
      t.integer :category, null: false, default: 0
      t.integer :rating, null: false, default: 5
      t.text    :note
      t.date    :eaten_on, null: false
      t.integer :coins_spent, null: false

      t.timestamps
    end
    add_index :snacks, [:user_id, :eaten_on]
  end
end

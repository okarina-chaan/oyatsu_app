class CreateEffortItems < ActiveRecord::Migration[8.0]
  def change
    create_table :effort_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name, null: false
      t.integer :coins_per_check, null: false, default: 1
      t.integer :position, null: false

      t.timestamps
    end
    add_index :effort_items, [ :user_id, :position ], unique: true
  end
end

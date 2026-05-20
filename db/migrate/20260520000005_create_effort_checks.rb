class CreateEffortChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :effort_checks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :effort_item, null: false, foreign_key: true
      t.date    :checked_on, null: false
      t.integer :coins_earned, null: false

      t.timestamps
    end
    add_index :effort_checks, [ :effort_item_id, :checked_on ], unique: true
    add_index :effort_checks, [ :user_id, :checked_on ]
  end
end

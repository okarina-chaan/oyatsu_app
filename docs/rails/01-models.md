# 01. ドメインモデル & マイグレーション

> 参照: [`00-overview.md`](./00-overview.md)

---

## 1. ER 図

```
┌───────────────────────────┐
│ User (Rails 8 auth)       │
│  - email_address          │
│  - password_digest        │
│  - name                   │
│  - snack_cost_in_coins ★  │   ← おやつ1個と交換するのに必要なコイン (default: 10)
└────────┬──────────────────┘
         │ has_many
         │
┌────────▼────────────────┐      ┌──────────────────────────┐
│ EffortItem (頑張り項目)  │──▶── │ EffortCheck (達成ログ)    │
│  - name                  │ 1:N │  - checked_on (date)     │
│  - coins_per_check       │     │  - coins_earned (int)    │
│  - position (1..3)       │     │  unique(item_id, date)   │
│  validate: per user max 3│     └──────────────────────────┘
└──────────────────────────┘
         │
         │ user has_many
         ▼
┌───────────────────────────┐
│ Snack (おやつ記録)         │
│  - name                   │
│  - category (enum)        │   yougashi / wagashi / shoppai
│  - rating (1..5)          │
│  - note (text)            │
│  - eaten_on (date)        │
│  - coins_spent (int)      │   記録時点の cost を snapshot
│  - photo (ActiveStorage)  │
└───────────────────────────┘
```

Rails 8 標準 auth ジェネレータが作る `Session`, `PasswordReset` 等は自動生成のまま。

---

## 2. 主要バリデーション

| Model         | 制約                                                              |
| ------------- | ----------------------------------------------------------------- |
| `User`        | `snack_cost_in_coins`: presence, 1..100                           |
| `EffortItem`  | `name`: presence, max 30文字 / `coins_per_check`: 1..10 / per user で `position` ユニーク, max 3件 |
| `EffortCheck` | `checked_on`: presence / `(effort_item_id, checked_on)` ユニーク / `coins_earned` は create 時に `effort_item.coins_per_check` から snapshot |
| `Snack`       | `name`: presence, max 60文字 / `rating`: 1..5 / `category`: enum / `eaten_on`: presence / `coins_spent` は create 時に `user.snack_cost_in_coins` から snapshot |

---

## 3. 補助メソッド（イメージ）

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_many :effort_items, -> { order(:position) }, dependent: :destroy
  has_many :effort_checks, dependent: :destroy
  has_many :snacks, dependent: :destroy

  def coin_balance
    coins_earned - coins_spent
  end

  def coins_earned
    effort_checks.sum(:coins_earned)
  end

  def coins_spent
    snacks.sum(:coins_spent)
  end

  def coins_until_next_snack
    [snack_cost_in_coins - coin_balance, 0].max
  end
end
```

```ruby
# app/models/effort_item.rb
class EffortItem < ApplicationRecord
  belongs_to :user
  has_many :effort_checks, dependent: :destroy

  validates :name, presence: true, length: { maximum: 30 }
  validates :coins_per_check, numericality: { in: 1..10 }
  validates :position, presence: true, uniqueness: { scope: :user_id }

  validate :user_effort_items_limit
  MAX_PER_USER = 3

  def checked_on?(date = Date.current)
    effort_checks.exists?(checked_on: date)
  end

  def today_check
    effort_checks.find_by(checked_on: Date.current)
  end

  private

  def user_effort_items_limit
    return if persisted?
    if user && user.effort_items.count >= MAX_PER_USER
      errors.add(:base, "頑張り項目は#{MAX_PER_USER}つまでです")
    end
  end
end
```

```ruby
# app/models/snack.rb
class Snack < ApplicationRecord
  belongs_to :user
  has_one_attached :photo

  enum :category, { yougashi: 0, wagashi: 1, shoppai: 2 }, prefix: true

  validates :name, presence: true, length: { maximum: 60 }
  validates :rating, numericality: { in: 1..5 }
  validates :eaten_on, presence: true

  scope :recent,     -> { order(eaten_on: :desc) }
  scope :this_month, -> { where(eaten_on: Date.current.all_month) }
end
```

---

## 4. マイグレーション

`rails generate authentication` を最初に実行した後、以下を追加。

```ruby
# db/migrate/xxx_add_app_columns_to_users.rb
class AddAppColumnsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :snack_cost_in_coins, :integer, default: 10, null: false
  end
end
```

```ruby
# db/migrate/xxx_create_effort_items.rb
class CreateEffortItems < ActiveRecord::Migration[8.0]
  def change
    create_table :effort_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name, null: false
      t.integer :coins_per_check, null: false, default: 1
      t.integer :position, null: false
      t.timestamps
    end
    add_index :effort_items, [:user_id, :position], unique: true
  end
end
```

```ruby
# db/migrate/xxx_create_effort_checks.rb
class CreateEffortChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :effort_checks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :effort_item, null: false, foreign_key: true
      t.date    :checked_on, null: false
      t.integer :coins_earned, null: false
      t.timestamps
    end
    add_index :effort_checks, [:effort_item_id, :checked_on], unique: true
    add_index :effort_checks, [:user_id, :checked_on]
  end
end
```

```ruby
# db/migrate/xxx_create_snacks.rb
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
```

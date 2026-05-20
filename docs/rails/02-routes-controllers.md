# 02. ルーティング & コントローラー

> 参照: [`00-overview.md`](./00-overview.md) / [`01-models.md`](./01-models.md)

---

## 1. config/routes.rb

```ruby
Rails.application.routes.draw do
  # Rails 8 標準 auth ジェネレータが追加する Routes はそのまま
  resource  :session
  resources :passwords, param: :token

  # アプリ本体
  root to: "home#show"
  resource  :home,     only: :show
  resource  :settings, only: %i[show update]

  resources :effort_items, except: %i[show] do
    resource :check, only: %i[create destroy], controller: "effort_checks"
  end

  resources :snacks
end
```

---

## 2. ApplicationController

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication # ← rails g authentication が追加
  allow_browser versions: :modern
end
```

---

## 3. HomeController

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def show
    @effort_items = Current.user.effort_items
    @balance      = Current.user.coin_balance
    @cost         = Current.user.snack_cost_in_coins
    @remaining    = Current.user.coins_until_next_snack
    @progress     = [@balance.to_f / @cost, 1.0].min
  end
end
```

---

## 4. EffortChecksController（チェック切替）

```ruby
# app/controllers/effort_checks_controller.rb
class EffortChecksController < ApplicationController
  before_action :set_effort_item

  def create
    @effort_item.effort_checks.find_or_create_by!(checked_on: Date.current) do |c|
      c.user = Current.user
      c.coins_earned = @effort_item.coins_per_check
    end
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  def destroy
    @effort_item.effort_checks.where(checked_on: Date.current).destroy_all
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  private

  def set_effort_item
    @effort_item = Current.user.effort_items.find(params[:effort_item_id])
  end
end
```

---

## 5. SnacksController

```ruby
# app/controllers/snacks_controller.rb
class SnacksController < ApplicationController
  before_action :set_snack, only: %i[show edit update destroy]

  def index
    @snacks      = Current.user.snacks.recent
    @month_count = Current.user.snacks.this_month.count
    @total_coins = Current.user.coins_spent
  end

  def new
    @snack = Current.user.snacks.build(eaten_on: Date.current, rating: 5)
  end

  def create
    @snack = Current.user.snacks.build(snack_params)
    @snack.coins_spent = Current.user.snack_cost_in_coins
    if @snack.save
      redirect_to snacks_path, notice: "ごほうびを記録しました 🎀"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit; end

  def update
    if @snack.update(snack_params)
      redirect_to snacks_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @snack.destroy!
    redirect_to snacks_path, notice: "削除しました"
  end

  private

  def set_snack
    @snack = Current.user.snacks.find(params[:id])
  end

  def snack_params
    params.expect(snack: [:name, :category, :rating, :note, :eaten_on, :photo])
  end
end
```

---

## 6. SettingsController

```ruby
# app/controllers/settings_controller.rb
class SettingsController < ApplicationController
  def show
    @effort_items = Current.user.effort_items
    @user = Current.user
  end

  def update
    Current.user.update!(settings_params)
    redirect_to settings_path, notice: "保存しました"
  end

  private

  def settings_params
    params.expect(user: [:snack_cost_in_coins])
  end
end
```

---

## 7. EffortItemsController（CRUD）

```ruby
# app/controllers/effort_items_controller.rb
class EffortItemsController < ApplicationController
  before_action :set_effort_item, only: %i[edit update destroy]

  def index
    @effort_items = Current.user.effort_items
  end

  def new
    @effort_item = Current.user.effort_items.build(
      position: (Current.user.effort_items.maximum(:position) || 0) + 1,
      coins_per_check: 1
    )
  end

  def create
    @effort_item = Current.user.effort_items.build(effort_item_params)
    if @effort_item.save
      redirect_to settings_path, notice: "頑張り項目を追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @effort_item.update(effort_item_params)
      redirect_to settings_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @effort_item.destroy!
    redirect_to settings_path, notice: "削除しました"
  end

  private

  def set_effort_item
    @effort_item = Current.user.effort_items.find(params[:id])
  end

  def effort_item_params
    params.expect(effort_item: [:name, :coins_per_check, :position])
  end
end
```

> `Current.user` は Rails 8 標準 auth ジェネレータが作成する `Current` モデルを使用。

class HomeController < ApplicationController
  def show
    @effort_items = Current.user.effort_items
    @balance      = Current.user.coin_balance
    @cost         = Current.user.snack_cost_in_coins
    @remaining    = Current.user.coins_until_next_snack
    @progress     = @cost.positive? ? [@balance.to_f / @cost, 1.0].min : 0.0
  end
end

class SnacksController < ApplicationController
  before_action :set_snack, only: %i[show edit update destroy]

  def index
    @snacks      = Current.user.snacks.recent
    @month_count = Current.user.snacks.this_month.count
    @total_coins = Current.user.coins_spent
  end

  def new
    if coins_insufficient?
      redirect_to root_path, alert: "コインが足りません！もう少し頑張ろう！" and return
    end
    @snack = Current.user.snacks.build(eaten_on: Date.current, rating: 5)
  end

  def create
    if coins_insufficient?
      redirect_to root_path, alert: "コインが足りません！もう少し頑張ろう！" and return
    end
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

  def coins_insufficient?
    Current.user.coin_balance < Current.user.snack_cost_in_coins
  end
end

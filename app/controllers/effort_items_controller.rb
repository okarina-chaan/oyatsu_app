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

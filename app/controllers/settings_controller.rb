class SettingsController < ApplicationController
  def show
    @user         = Current.user
    @effort_items = Current.user.effort_items
  end

  def update
    if Current.user.update(settings_params)
      redirect_to settings_path, notice: "保存しました"
    else
      @user         = Current.user
      @effort_items = Current.user.effort_items
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.expect(user: [ :snack_cost_in_coins ])
  end
end

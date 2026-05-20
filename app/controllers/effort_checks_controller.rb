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
      format.turbo_stream { render :create }
      format.html { redirect_to root_path }
    end
  end

  private

  def set_effort_item
    @effort_item = Current.user.effort_items.find(params[:effort_item_id])
  end
end

class DailyCheckinsController < ApplicationController
  # 1日1回の一括確定。
  # checkbox で選ばれた effort_item_ids を受け取り、まとめて effort_checks に記録、
  # User#last_checkin_on を today に更新する。
  def create
    if Current.user.checked_in_today?
      redirect_to root_path, alert: "今日はすでに「今日もがんばった！」しました 🎀" and return
    end

    selected_ids = Array(params[:effort_item_ids]).map(&:to_s)
    items = Current.user.effort_items.where(id: selected_ids)

    ActiveRecord::Base.transaction do
      items.each do |item|
        item.effort_checks.find_or_create_by!(checked_on: Date.current) do |check|
          check.user = Current.user
          check.coins_earned = item.coins_per_check
        end
      end
      Current.user.update!(last_checkin_on: Date.current)
    end

    if items.any?
      redirect_to root_path, notice: "今日もえらい！コインが反映されました 🪙"
    else
      redirect_to root_path, notice: "今日もおつかれさま。明日もがんばろう ☕"
    end
  end
end

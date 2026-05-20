class EffortCheck < ApplicationRecord
  belongs_to :user
  belongs_to :effort_item

  validates :checked_on, presence: true
  validates :coins_earned, presence: true,
                           numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :effort_item_id, uniqueness: { scope: :checked_on }

  before_validation :snapshot_coins_earned, on: :create

  scope :on, ->(date) { where(checked_on: date) }

  private

  def snapshot_coins_earned
    self.coins_earned ||= effort_item&.coins_per_check
  end
end

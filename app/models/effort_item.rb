class EffortItem < ApplicationRecord
  MAX_PER_USER = 3

  belongs_to :user
  has_many :effort_checks, dependent: :destroy

  validates :name, presence: true, length: { maximum: 30 }
  validates :coins_per_check, presence: true,
                              numericality: { only_integer: true, in: 1..10 }
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: :user_id }

  validate :user_effort_items_limit

  def checked_on?(date = Date.current)
    effort_checks.exists?(checked_on: date)
  end

  def today_check
    effort_checks.find_by(checked_on: Date.current)
  end

  private

  def user_effort_items_limit
    return if persisted?
    return unless user
    if user.effort_items.count >= MAX_PER_USER
      errors.add(:base, "頑張り項目は#{MAX_PER_USER}つまでです")
    end
  end
end

class Snack < ApplicationRecord
  belongs_to :user

  enum :category, { yougashi: 0, wagashi: 1, shoppai: 2 }, prefix: true

  validates :name, presence: true, length: { maximum: 60 }
  validates :rating, presence: true,
                     numericality: { only_integer: true, in: 1..5 }
  validates :eaten_on, presence: true
  validates :coins_spent, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recent,     -> { order(eaten_on: :desc, created_at: :desc) }
  scope :this_month, -> { where(eaten_on: Date.current.all_month) }
end

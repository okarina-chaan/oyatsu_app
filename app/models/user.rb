class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :effort_items, -> { order(:position) }, dependent: :destroy
  has_many :effort_checks, dependent: :destroy
  has_many :snacks, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :snack_cost_in_coins, presence: true,
                                  numericality: { only_integer: true, in: 1..100 }

  # ----- コイン残高関連 -----
  def coin_balance
    coins_earned - coins_spent
  end

  def coins_earned
    effort_checks.sum(:coins_earned)
  end

  def coins_spent
    snacks.sum(:coins_spent)
  end

  def coins_until_next_snack
    [ snack_cost_in_coins - coin_balance, 0 ].max
  end

  # ----- 1日1回の確定 (今日もがんばった！) -----
  def checked_in_today?
    last_checkin_on == Date.current
  end
end

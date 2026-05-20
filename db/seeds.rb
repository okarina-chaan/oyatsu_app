# This file should ensure the existence of records required to run the application in every environment.
# 開発用のシードデータです。`bin/rails db:seed` で投入します。

user = User.find_or_create_by!(email_address: "test@example.com") do |u|
  u.password = "password"
  u.name = "おかりな"
  u.snack_cost_in_coins = 10
end

# 頑張り項目
[
  ["1日10000歩あるく", 1, 1],
  ["水を2L飲む",        1, 2],
  ["菓子パンを我慢",     2, 3]
].each do |name, coins, pos|
  user.effort_items.find_or_create_by!(position: pos) do |item|
    item.name = name
    item.coins_per_check = coins
  end
end

# 直近のチェック例
user.effort_items.first(2).each do |item|
  item.effort_checks.find_or_create_by!(checked_on: Date.current) do |check|
    check.user = user
    check.coins_earned = item.coins_per_check
  end
end

# おやつ履歴例
[
  ["苺ショートケーキ",  :yougashi, 4, "5/20", "クリームが軽くて生地がふわふわ。苺も大粒で甘酸っぱくてしあわせ〜"],
  ["豆大福",            :wagashi,  5, "5/16", "近所の和菓子屋さんで朝一に買ったやつ。塩気がきいてて餡が上品。"],
  ["うすしおポテチ",    :shoppai,  3, "5/12", "金曜の夜に映画見ながら。半袋でやめられた、えらい。"]
].each do |name, cat, rating, date, note|
  m, d = date.split("/").map(&:to_i)
  eaten_on = Date.new(Date.current.year, m, d)
  user.snacks.find_or_create_by!(name: name, eaten_on: eaten_on) do |snack|
    snack.category    = cat
    snack.rating      = rating
    snack.note        = note
    snack.coins_spent = user.snack_cost_in_coins
  end
end

# 06. 認証 / セットアップ手順 / テスト / 拡張余白

> 参照: [`00-overview.md`](./00-overview.md)

---

## 1. 認証セットアップ

```bash
bin/rails generate authentication
```

これで以下が生成される：

- `User` モデル（`has_secure_password`、`email_address`、`password_digest`）
- `Session` モデル + `SessionsController`
- `PasswordsController`（リセット）
- `Authentication` concern（→ `ApplicationController` に include）
- `Current` モデル（`Current.user`, `Current.session`）

`User` に追加カラム（`name`, `snack_cost_in_coins`）はマイグレーションで足す（[`01-models.md`](./01-models.md) 参照）。

`User` モデルに本ドキュメントの拡張（`has_many :effort_items` 等、`coin_balance` 等）を追記する。

サインアップ画面はジェネレータが作らないので：
- 個人アプリ最初期は **seed ユーザー** で OK
- 公開するなら自前で `RegistrationsController#new/create` を足す

---

## 2. セットアップ手順（Claude Code への指示用）

```bash
# 1. テンプレ依存セットアップ
bundle install
bin/setup

# 2. daisyUI 導入（現行 package.json には未追加）
npm install -D daisyui@latest

# 3. 認証ジェネレータ
bin/rails generate authentication

# 4. モデル & マイグレーション
bin/rails g migration AddAppColumnsToUsers name:string snack_cost_in_coins:integer
bin/rails g model EffortItem  user:references name:string coins_per_check:integer position:integer
bin/rails g model EffortCheck user:references effort_item:references checked_on:date coins_earned:integer
bin/rails g model Snack       user:references name:string category:integer rating:integer note:text eaten_on:date coins_spent:integer

# (それぞれのマイグレーションファイルは 01-models.md に合わせて手直し)

bin/rails db:create db:migrate

# 5. ActiveStorage
bin/rails active_storage:install
bin/rails db:migrate

# 6. コントローラー / ビュー / Stimulus コントローラー作成
bin/rails g controller Home show
bin/rails g controller EffortItems
bin/rails g controller EffortChecks
bin/rails g controller Snacks
bin/rails g controller Settings show

bin/rails g stimulus effort-check
bin/rails g stimulus chip-group
bin/rails g stimulus heart-rating
bin/rails g stimulus stepper
bin/rails g stimulus photo-preview

# 7. seed (開発用)
bin/rails db:seed
```

---

## 3. seed (`db/seeds.rb`)

```ruby
user = User.create!(
  email_address: "test@example.com",
  password: "password",
  name: "おかりな",
  snack_cost_in_coins: 10
)

[
  ["1日10000歩あるく", 1, 1],
  ["水を2L飲む",        1, 2],
  ["菓子パンを我慢",     2, 3],
].each do |name, coins, pos|
  user.effort_items.create!(name: name, coins_per_check: coins, position: pos)
end

# 直近のチェック例
user.effort_items.first(2).each do |item|
  item.effort_checks.create!(
    user: user, checked_on: Date.current, coins_earned: item.coins_per_check
  )
end

# おやつ履歴例
[
  ["苺ショートケーキ",      :yougashi, 4, "5/20", "クリームが軽くて生地がふわふわ。苺も大粒で甘酸っぱくてしあわせ〜"],
  ["豆大福",                :wagashi,  5, "5/16", "近所の和菓子屋さんで朝一に買ったやつ。塩気がきいてて餡が上品。"],
  ["うすしおポテチ",         :shoppai,  3, "5/12", "金曜の夜に映画見ながら。半袋でやめられた、えらい。"],
].each do |name, cat, rating, date, note|
  m, d = date.split("/").map(&:to_i)
  user.snacks.create!(
    name: name, category: cat, rating: rating,
    eaten_on: Date.new(Date.current.year, m, d),
    note: note, coins_spent: user.snack_cost_in_coins
  )
end
```

---

## 4. テスト方針（最小）

- **Model spec/test**:
  - `User#coin_balance`, `#coins_until_next_snack`
  - `EffortItem` のバリデーション（max 3、name 必須）
  - `EffortCheck` の (effort_item, date) ユニーク制約
  - `Snack` の rating 1..5、category enum
- **System test**:
  1. ログインしてホームを開く → 残高表示
  2. 頑張り項目をチェック → コインが増える
  3. 残高 ≥ コストで「おやつ記録」ボタンが押せる
  4. 記録するとコインが減る → 一覧に追加される
  5. 設定画面で交換レートを変更 → ホームの「あと◯コイン」が更新される

DB:
- 開発 / 本番: PostgreSQL
- テスト: SQLite（テンプレ標準）  
  `config/database.yml` の `test` セクションを適宜調整。

---

## 5. 翻訳ファイル

```yaml
# config/locales/ja.yml
ja:
  date:
    formats:
      long: "%-m月%-d日（%a）"
    abbr_day_names: [日, 月, 火, 水, 木, 金, 土]

  snacks:
    categories:
      yougashi: "🍰 洋菓子"
      wagashi:  "🍡 和菓子"
      shoppai:  "🥨 しょっぱい"

  activerecord:
    models:
      user: ユーザー
      effort_item: 頑張り項目
      effort_check: 達成ログ
      snack: おやつ
    attributes:
      user:
        snack_cost_in_coins: 交換コイン数
      effort_item:
        name: 名前
        coins_per_check: 1回あたりコイン
      snack:
        name: 名前
        category: 種類
        rating: 満足度
        note: 感想
        eaten_on: 食べた日
        photo: 写真
```

`config/application.rb`:

```ruby
config.i18n.default_locale = :ja
config.time_zone = "Tokyo"
```

---

## 6. 将来の拡張（今回は対象外、設計余白として）

- ホームのリマインダー通知（`solid_queue` で定時 Job）
- お気に入りフラグ（`Snack.favorite` カラム or `Favorites` テーブル）
- グラフ（週次達成率、月別おやつ消費）
- 写真の Active Storage variant / 圧縮
- PWA 化（テンプレに `app/views/pwa/` あり）
- 月のリセット / アーカイブ機能
- 「がんばりすぎ防止」アラート（連続未達成日数）
- 複数ユーザー / 公開機能（コミュニティ化）

---

## 7. 進め方の推奨順序

1. 認証ジェネレータ → User 拡張 → seed が動く
2. 設定画面（`/settings`）で交換レートと項目編集が動く
3. ホーム画面でチェックトグル → コインカウンタ動く
4. おやつ記録 → 一覧で表示される
5. デザイン CSS を `styles.css` から `app/assets/tailwind/application.css` に移植
6. Stimulus でフォームのインタラクションを仕上げる
7. システムテスト・最小バリデーション

「動く骨組み → デザイン → インタラクション」の順で進めると詰まりにくい。

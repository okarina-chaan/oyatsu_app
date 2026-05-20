# おやつ貯金 — Rails 設計提案

> Rails 8 + Hotwire (Turbo + Stimulus) + Tailwind + daisyUI + PostgreSQL  
> 認証: Rails 8 標準 `bin/rails generate authentication`  
> このドキュメント群は Claude Code (CLI) で実装するためのインプットです。

---

## ファイル構成

| ファイル                                          | 内容                                          |
| ------------------------------------------------- | --------------------------------------------- |
| [`00-overview.md`](./00-overview.md)              | このファイル（全体方針 / 画面⇔ルート対応表） |
| [`01-models.md`](./01-models.md)                  | ドメインモデル / ER 図 / マイグレーション     |
| [`02-routes-controllers.md`](./02-routes-controllers.md) | ルーティング / コントローラー骨子      |
| [`03-views.md`](./03-views.md)                    | ビュー (ERB) 構成 と サンプルコード           |
| [`04-stimulus.md`](./04-stimulus.md)              | Stimulus コントローラー設計                   |
| [`05-styling.md`](./05-styling.md)                | Tailwind / daisyUI テーマ / カスタム CSS      |
| [`06-setup-and-misc.md`](./06-setup-and-misc.md)  | 認証セットアップ / 手順 / テスト / 拡張余白   |

---

## 1. 全体方針

- **モバイルファースト**。デスクトップは中央に 414px のアプリペインを置くレイアウト。
- **画面遷移は Turbo Drive**、頑張りチェックや満足度入力など小さなインタラクションは **Stimulus + Turbo Frame / Turbo Stream**。
- **コイン残高は派生値**。`effort_checks` (獲得) − `snacks` (消費) を都度集計（必要なら scope/メソッドにまとめてキャッシュ）。
- **enum・状態はモデル層に閉じ込め**、View は薄く保つ。
- **デザインは現行 HTML モック準拠**。`M PLUS Rounded 1c` + パステル配色をそのまま Tailwind theme に取り込む。

---

## 2. 画面 → ルート 対応表

| 画面 (モック)  | URL              | 主なリンク先                            |
| -------------- | ---------------- | --------------------------------------- |
| ① ホーム       | `/`              | チェックボタン → 同 URL (Turbo Stream)  |
| ② 設定         | `/settings`      | 各項目編集 → `/effort_items/:id/edit`   |
| ③ おやつ記録   | `/snacks/new`    | 送信 → `/snacks` (一覧へ)               |
| ④ おやつ一覧   | `/snacks`        | カードタップ → `/snacks/:id`            |
| (拡張) サインイン | `/session/new`| -                                       |

ボトムナビは `home / list (snacks) / record (snacks#new) / settings` の 4 タブ。

---

## 3. 全エンドポイント一覧

| Method | Path                                  | Controller#Action          | 用途                               |
| ------ | ------------------------------------- | -------------------------- | ---------------------------------- |
| GET    | `/`                                   | `home#show`                | ホーム画面                          |
| GET    | `/settings`                           | `settings#show`            | 設定画面                            |
| PATCH  | `/settings`                           | `settings#update`          | 交換レート更新                      |
| GET    | `/effort_items`                       | `effort_items#index`       | 設定 → 項目一覧                     |
| GET    | `/effort_items/new`                   | `effort_items#new`         | 項目追加                            |
| POST   | `/effort_items`                       | `effort_items#create`      |                                     |
| GET    | `/effort_items/:id/edit`              | `effort_items#edit`        |                                     |
| PATCH  | `/effort_items/:id`                   | `effort_items#update`      |                                     |
| DELETE | `/effort_items/:id`                   | `effort_items#destroy`     |                                     |
| POST   | `/effort_items/:id/check`             | `effort_checks#create`     | 今日のチェック ON                   |
| DELETE | `/effort_items/:id/check`             | `effort_checks#destroy`    | 今日のチェック OFF                  |
| GET    | `/snacks`                             | `snacks#index`             | おやつ一覧                          |
| GET    | `/snacks/new`                         | `snacks#new`               | おやつ記録フォーム                  |
| POST   | `/snacks`                             | `snacks#create`            |                                     |
| GET    | `/snacks/:id`                         | `snacks#show`              | 詳細（拡張用）                      |
| PATCH  | `/snacks/:id`                         | `snacks#update`            |                                     |
| DELETE | `/snacks/:id`                         | `snacks#destroy`           |                                     |
| (auth) | `/session`, `/passwords`              | Rails 8 標準               | サインイン等                        |

---

## 4. デザイン参照

現行 hi-fi モック：

- `おやつ貯金.html` — エントリーポイント
- `styles.css` — CSS 変数 & コンポーネント
- `icons.jsx` — 貯金箱・コイン・カテゴリアイコン SVG（ERB partial にコピペで OK）
- `screens.jsx` — ホーム / 設定 / 記録 / 一覧の見た目

ERB に書き起こす際は `icons.jsx` の `<PiggyBank />`, `<Coin />`, `<SnackCake/Mochi/Chips />` の SVG をそのまま `app/views/shared/_*.html.erb` に貼ればよい。

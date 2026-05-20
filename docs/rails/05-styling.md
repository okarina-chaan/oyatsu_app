# 05. スタイリング（Tailwind / daisyUI）

> 参照: [`03-views.md`](./03-views.md) / 元モック `styles.css`

---

## 1. daisyUI テーマ定義（モックの配色を移植）

```js
// tailwind.config.js
module.exports = {
  // ...
  plugins: [require("daisyui")],
  daisyui: {
    themes: [{
      oyatsu: {
        "primary":         "#F08858",  // peach-500
        "primary-content": "#ffffff",
        "secondary":       "#F47A95",  // pink-500
        "accent":          "#F5C645",  // coin
        "neutral":         "#3F2A1A",  // ink-900
        "base-100":        "#FFF8F0",  // cream
        "base-200":        "#FDF1E3",
        "base-300":        "#F2E4D4",
        "base-content":    "#3F2A1A",
        "info":            "#A8D8E8",
        "success":         "#9DD3A6",
        "warning":         "#FFE48A",
        "error":           "#E84F5E",
        "--rounded-box":   "1.5rem",
        "--rounded-btn":   "9999px",
        "--rounded-badge": "9999px",
      },
    }],
  },
};
```

適用は HTML 側で：

```erb
<html data-theme="oyatsu">
```

---

## 2. インストール

```bash
npm install -D daisyui@latest
```

`tailwind.config.js` の `plugins` に `require("daisyui")` を追加（上記）。
本テンプレは `tailwindcss-rails` v4 系なので、`app/assets/tailwind/application.css` の頭で
`@plugin "daisyui";` 形式の宣言も使える。バージョンに合わせて選択。

---

## 3. カスタム CSS の移植先

モックの貯金箱・コイン・チェックバッジなどは daisyUI コンポーネントだけでは出せない。
現行 `styles.css` の以下を `app/assets/tailwind/application.css` に **そのまま `@layer components` として** 移植する：

| 元 class               | 用途                                |
| ---------------------- | ----------------------------------- |
| `.app`, `.app-bg`      | アプリ全体の枠 / 背景グラデ          |
| `.status-bar`          | モバイル風ステータスバー            |
| `.topbar`              | 画面上部                             |
| `.card`, `.card-soft`  | 主要カード                           |
| `.section-title .pip`  | セクション見出しの▪️                  |
| `.coin-pill`           | コインバッジ                         |
| `.btn-primary`, `.btn-ghost` | ボタン2系統                    |
| `.bottom-nav`, `.nav-item`, `.nav-icon` | ボトムナビ          |
| `.effort-row`, `.effort-emoji`, `.effort-text`, `.check` | 頑張り行 |
| `.snack-card`, `.snack-thumb`, `.snack-info` | おやつ一覧カード     |
| `.chip`                | チップ（daisyUI badge と被るので独自で） |
| `.input`, `.field-label` | フォーム                           |
| `.heart-row`, `.heart` | ハート評価                           |
| `.stepper`             | +/− カウンタ                        |

CSS 変数（`--peach-300` 等）は `@layer base` の `:root { ... }` で宣言。

---

## 4. ファイル構成

```
app/assets/tailwind/
└─ application.css        # @import "tailwindcss"; + @layer components 移植
```

ざっくりの雛形：

```css
@import "tailwindcss";

@layer base {
  :root {
    --cream:        #FFF8F0;
    --cream-warm:   #FDF1E3;
    --peach-300:    #FFB088;
    --peach-500:    #F08858;
    --peach-700:    #C56A3D;
    --pink-500:     #F47A95;
    --coin-light:   #FFE48A;
    --coin:         #F5C645;
    --coin-deep:    #D69B1F;
    --ink-900:      #3F2A1A;
    --ink-500:      #8C7567;
    --line:         #F2E4D4;
    /* ...残り */
  }
  body {
    font-family: "M PLUS Rounded 1c", system-ui, sans-serif;
    background: var(--cream);
    color: var(--ink-900);
  }
}

@layer components {
  .card { /* ...モックそのまま */ }
  .btn-primary { /* ... */ }
  .effort-row { /* ... */ }
  /* 以降、モックの styles.css の各 class をコピペ */
}
```

---

## 5. フォント読み込み

```erb
<%# app/views/layouts/application.html.erb の head %>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link
  href="https://fonts.googleapis.com/css2?family=M+PLUS+Rounded+1c:wght@400;500;700;800&family=Fraunces:opsz,wght@9..144,500..800&display=swap"
  rel="stylesheet">
```

---

## 6. レスポンシブ方針

モバイル: そのまま全幅。  
デスクトップ: `body` レベルで以下のような中央寄せをする：

```css
@media (min-width: 768px) {
  body {
    display: grid;
    place-items: center;
    background: #f0eee9; /* キャンバス色 */
  }
  .app-shell {
    width: 414px;
    min-height: 844px;
    border-radius: 24px;
    box-shadow: 0 12px 40px rgba(0,0,0,0.08);
    overflow: hidden;
    background: var(--cream);
  }
}
```

スマホで開くと普通の Web ページ、PC で開くとアプリ風に見える。

---

## 7. daisyUI を「使う / 使わない」判断

| 要素                    | daisyUI 使用    | 理由                                  |
| ----------------------- | --------------- | ------------------------------------- |
| 貯金箱カード            | ✗（独自）       | 形・装飾が独自                         |
| 頑張り行 / おやつカード | ✗（独自）       | レイアウト独自                         |
| ボトムナビ              | ✗（独自）       | 形が独自                               |
| ボタン                  | △（独自優先）   | 影付き押し下げ感がモック準拠           |
| 入力フォーム            | ◯ baseは利用可  | 色だけテーマで吸収                    |
| アラート / トースト     | ◯               | flash 表示に `alert` クラス便利       |
| モーダル                | ◯               | 削除確認など                           |
| バッジ                  | ✗（chip 独自）  | 形が違う                              |

基本「テーマ色 + base コンポーネント」のみ daisyUI、見た目独自のものはモック流用。

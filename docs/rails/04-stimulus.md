# 04. Stimulus コントローラー

> 参照: [`03-views.md`](./03-views.md)

---

## 1. 一覧

| Controller          | 役割                                                      | 対象画面          |
| ------------------- | --------------------------------------------------------- | ----------------- |
| `effort-check`      | チェック ON/OFF の見た目を楽観的に切替（Turbo が同期）    | ホーム            |
| `chip-group`        | 排他選択（カテゴリチップ、フィルター）                    | 記録 / 一覧       |
| `heart-rating`      | 1–5 のハート選択、hidden input に値を反映                 | 記録              |
| `stepper`           | +/− で数値を操作（hidden input or form 直接送信）         | 設定              |
| `photo-preview`     | `<input type="file">` の選択画像をプレビュー              | 記録              |

配置場所: `app/javascript/controllers/`  
登録: ジェネレータ (`bin/rails g stimulus chip-group` 等) で自動登録される。

---

## 2. `heart_rating_controller.js`

```js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["heart", "input"];
  static values  = { value: Number };

  connect() { this.render(); }

  pick(event) {
    this.valueValue = Number(event.params.index);
    this.inputTarget.value = this.valueValue;
    this.render();
  }

  render() {
    this.heartTargets.forEach((el, i) => {
      el.classList.toggle("filled", i < this.valueValue);
    });
  }
}
```

---

## 3. `chip_group_controller.js`

```js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  select(event) {
    const label = event.currentTarget;
    this.element.querySelectorAll(".chip").forEach((el) => {
      el.classList.toggle("active", el === label);
    });
  }
}
```

---

## 4. `effort_check_controller.js`

サーバ通信は `button_to` + `turbo_frame` 任せ。クリック直後の見た目だけ
即座に切り替えて、レスポンスで上書きされる。

```js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { checked: Boolean };

  connect() {
    this.render();
  }

  // form submit の直前にトグル
  optimistic(event) {
    this.checkedValue = !this.checkedValue;
    this.render();
  }

  render() {
    this.element.classList.toggle("done", this.checkedValue);
  }
}
```

> `form` 側に `data-action="submit->effort-check#optimistic"` を追加して使用。

---

## 5. `stepper_controller.js`

設定画面の `coins_per_check` / `snack_cost_in_coins` 用。
`+`/`-` で値を変えて、ボタン押下で submit（あるいは Turbo Stream で即時保存）。

```js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "display"];
  static values  = { min: { type: Number, default: 1 },
                     max: { type: Number, default: 99 } };

  inc() { this.set(Number(this.inputTarget.value) + 1); }
  dec() { this.set(Number(this.inputTarget.value) - 1); }

  set(v) {
    const clamped = Math.max(this.minValue, Math.min(this.maxValue, v));
    this.inputTarget.value = clamped;
    if (this.hasDisplayTarget) this.displayTarget.textContent = clamped;
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }));
  }
}
```

---

## 6. `photo_preview_controller.js`

```js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview"];

  load() {
    const file = this.inputTarget.files?.[0];
    if (!file) { this.previewTarget.style.backgroundImage = ""; return; }
    const url = URL.createObjectURL(file);
    this.previewTarget.style.backgroundImage = `url(${url})`;
    this.previewTarget.classList.add("has-image");
  }
}
```

---

## 7. ファイル命名規約

Rails の Stimulus 命名は `kebab-case`（HTML 上）/ `snake_case`（ファイル名）。

- HTML: `data-controller="heart-rating"`
- File: `app/javascript/controllers/heart_rating_controller.js`

Importmap ではなく `jsbundling-rails`（テンプレ採用）なので、
`app/javascript/controllers/index.js` でまとめて登録すれば動く。

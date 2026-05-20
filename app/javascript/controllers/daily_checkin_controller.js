import { Controller } from "@hotwired/stimulus";

// ホーム画面の「今日の頑張り」用。
// 各 effort_item のチェックボックスの選択数を見出し横のカウンタに反映する。
export default class extends Controller {
  static targets = ["counter", "submit"];
  static values  = { checkedIn: Boolean };

  updateCounter() {
    if (!this.hasCounterTarget) return;
    const inputs = this.element.querySelectorAll('input[name="effort_item_ids[]"]');
    const total = inputs.length;
    const selected = Array.from(inputs).filter((i) => i.checked).length;
    this.counterTarget.textContent = `${selected} / ${total}`;
  }
}

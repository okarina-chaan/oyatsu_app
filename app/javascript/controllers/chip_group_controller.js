import { Controller } from "@hotwired/stimulus";

// 排他選択 chip グループ。
// 子要素 .chip の click で active クラスを付け替える。
export default class extends Controller {
  select(event) {
    const label = event.currentTarget;
    this.element.querySelectorAll(".chip").forEach((el) => {
      el.classList.toggle("active", el === label);
    });
  }
}

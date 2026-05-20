import { Controller } from "@hotwired/stimulus";

// Optimistic にチェック表示を切替えるだけ。
// 実体は button_to + turbo_frame でサーバが上書きする。
export default class extends Controller {
  static values = { checked: Boolean };

  connect() {
    this.render();
  }

  optimistic() {
    this.checkedValue = !this.checkedValue;
    this.render();
  }

  checkedValueChanged() {
    this.render();
  }

  render() {
    this.element.classList.toggle("done", this.checkedValue);
  }
}

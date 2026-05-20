import { Controller } from "@hotwired/stimulus";

// 1-5 のハート選択。hidden input に値を反映。
export default class extends Controller {
  static targets = ["heart", "input"];
  static values  = { value: { type: Number, default: 5 } };

  connect() {
    this.render();
  }

  pick(event) {
    this.valueValue = Number(event.params.index);
    if (this.hasInputTarget) this.inputTarget.value = this.valueValue;
    this.render();
  }

  valueValueChanged() {
    this.render();
  }

  render() {
    this.heartTargets.forEach((el, i) => {
      el.classList.toggle("filled", i < this.valueValue);
      el.textContent = i < this.valueValue ? "♥" : "♡";
    });
  }
}

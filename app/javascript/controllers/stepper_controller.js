import { Controller } from "@hotwired/stimulus";

// +/− で数値を増減する。
// hidden / number input に値を反映、change イベントを発火。
export default class extends Controller {
  static targets = ["input", "display"];
  static values  = {
    min: { type: Number, default: 1 },
    max: { type: Number, default: 99 }
  };

  inc() { this.set(Number(this.inputTarget.value) + 1); }
  dec() { this.set(Number(this.inputTarget.value) - 1); }

  set(v) {
    const clamped = Math.max(this.minValue, Math.min(this.maxValue, v));
    this.inputTarget.value = clamped;
    if (this.hasDisplayTarget) this.displayTarget.textContent = clamped;
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }));
  }
}

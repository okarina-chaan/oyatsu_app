import { Controller } from "@hotwired/stimulus";

// <input type="file"> で選択された画像をプレビュー表示する。
export default class extends Controller {
  static targets = ["input", "preview"];

  load() {
    const file = this.inputTarget.files?.[0];
    if (!file) {
      this.previewTarget.style.backgroundImage = "";
      this.previewTarget.classList.remove("has-image");
      return;
    }
    const url = URL.createObjectURL(file);
    this.previewTarget.style.backgroundImage = `url(${url})`;
    this.previewTarget.classList.add("has-image");
  }
}

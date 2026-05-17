import { Controller } from "@hotwired/stimulus";

/**
 * Enable 儲存 / 新增 only when the name field differs from its initial value
 * (edit rows) or is non-empty (add row).
 */
export default class extends Controller {
  static targets = ["nameInput", "submitButton"];

  static values = {
    mode: { type: String, default: "edit" }
  };

  connect() {
    this.originalValue = this.nameInputTarget.value.trim();
    this.sync();
  }

  sync() {
    const current = this.nameInputTarget.value.trim();
    const dirty =
      this.modeValue === "add"
        ? current.length > 0
        : current !== this.originalValue;

    this.submitButtonTarget.disabled = !dirty;
    this.submitButtonTarget.classList.toggle("opacity-40", !dirty);
    this.submitButtonTarget.classList.toggle("pointer-events-none", !dirty);
    this.submitButtonTarget.setAttribute("aria-disabled", dirty ? "false" : "true");
  }
}

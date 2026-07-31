import { Controller } from "@hotwired/stimulus";

/**
 * Mobile (<lg): while a 金額 input is focused, hide the chart card so the form
 * keeps room above the software keyboard. The toggled class is max-lg: scoped,
 * so desktop is unaffected without any media-query logic here.
 */
export default class extends Controller {
  static targets = ["input", "collapsible"];

  connect() {
    this.element.addEventListener("focusin", this.#onFocusIn, true);
    this.element.addEventListener("focusout", this.#onFocusOut, true);
  }

  disconnect() {
    this.element.removeEventListener("focusin", this.#onFocusIn, true);
    this.element.removeEventListener("focusout", this.#onFocusOut, true);
    this.#setCollapsed(false);
  }

  #onFocusIn = (ev) => {
    if (!this.inputTargets.includes(ev.target)) return;
    this.#setCollapsed(true);
  };

  #onFocusOut = () => {
    // setTimeout, not rAF: rAF stalls when the page isn't rendering frames
    // (occluded window, iOS throttling) and the card would stay collapsed.
    window.setTimeout(() => {
      const active = document.activeElement;
      const stillAmount = this.inputTargets.some((el) => el === active || el.contains(active));
      if (!stillAmount) this.#setCollapsed(false);
    });
  };

  #setCollapsed(on) {
    this.collapsibleTargets.forEach((el) => el.classList.toggle("max-lg:hidden", on));
  }
}

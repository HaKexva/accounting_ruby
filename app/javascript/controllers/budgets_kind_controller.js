import { Controller } from "@hotwired/stimulus";

/** Switch 收入 / 支出 budget panels (sliding pill segment control). */
export default class extends Controller {
  static targets = ["kindSelect", "kindButton", "track", "indicator", "revenuePanel", "expenditurePanel"];

  connect() {
    this._onResize = () => this.#positionIndicator();
    window.addEventListener("resize", this._onResize);
    this.sync();
    requestAnimationFrame(() => this.#positionIndicator());
  }

  disconnect() {
    window.removeEventListener("resize", this._onResize);
  }

  pickKind(event) {
    const kind = event.currentTarget.dataset.kindValue;
    if (!kind) return;

    if (this.hasKindSelectTarget) {
      this.kindSelectTarget.value = kind;
    }
    this.sync();
  }

  sync(event) {
    const value = this.#kindValueFrom(event);

    if (this.hasKindSelectTarget && this.kindSelectTarget.value !== value) {
      this.kindSelectTarget.value = value;
    }

    const showRevenue = value === "revenue";
    this.revenuePanelTarget.classList.toggle("hidden", !showRevenue);
    this.expenditurePanelTarget.classList.toggle("hidden", showRevenue);

    this.kindButtonTargets.forEach((button) => {
      const active = button.dataset.kindValue === value;
      button.setAttribute("aria-pressed", active ? "true" : "false");
      button.classList.toggle(SEGMENTED_ACTIVE_CLASS, active);
      button.classList.toggle(SEGMENTED_INACTIVE_CLASS, !active);
    });

    this.#positionIndicator();
  }

  #positionIndicator() {
    if (!this.hasIndicatorTarget || !this.hasTrackTarget) return;

    const value = this.#kindValueFrom();
    const active = this.kindButtonTargets.find((button) => button.dataset.kindValue === value);
    if (!active) return;

    const trackRect = this.trackTarget.getBoundingClientRect();
    const buttonRect = active.getBoundingClientRect();
    const left = buttonRect.left - trackRect.left;

    this.indicatorTarget.style.width = `${buttonRect.width}px`;
    this.indicatorTarget.style.transform = `translateX(${left}px)`;
    this.indicatorTarget.style.opacity = "1";
  }

  #kindValueFrom(event) {
    if (event?.currentTarget?.dataset?.kindValue) {
      return this.#normalizeKind(event.currentTarget.dataset.kindValue);
    }
    if (event?.target === this.kindSelectTarget) {
      return this.#normalizeKind(event.target.value);
    }
    return this.#normalizeKind(this.kindSelectTarget?.value);
  }

  #normalizeKind(value) {
    return value === "expenditure" ? "expenditure" : "revenue";
  }
}

const SEGMENTED_ACTIVE_CLASS = "text-foreground";
const SEGMENTED_INACTIVE_CLASS = "text-muted-foreground";

import { Controller } from "@hotwired/stimulus";

/** Switch 消費類別 / 支付方式 / 支付平台 panels on the settings page. */
export default class extends Controller {
  static targets = [
    "kindSelect",
    "kindButton",
    "track",
    "indicator",
    "categoryPanel",
    "paymentMethodPanel",
    "paymentPlatformPanel"
  ];

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
    const kind = this.#kindValueFrom(event);

    if (this.hasKindSelectTarget && this.kindSelectTarget.value !== kind) {
      this.kindSelectTarget.value = kind;
    }

    this.categoryPanelTarget.classList.toggle("hidden", kind !== "category");
    this.paymentMethodPanelTarget.classList.toggle("hidden", kind !== "payment_method");
    this.paymentPlatformPanelTarget.classList.toggle("hidden", kind !== "payment_platform");

    this.kindButtonTargets.forEach((button) => {
      const active = button.dataset.kindValue === kind;
      button.setAttribute("aria-pressed", active ? "true" : "false");
      button.classList.toggle(SEGMENTED_ACTIVE_CLASS, active);
      button.classList.toggle(SEGMENTED_INACTIVE_CLASS, !active);
    });

    this.#positionIndicator();
  }

  #positionIndicator() {
    if (!this.hasIndicatorTarget || !this.hasTrackTarget) return;

    const kind = this.#kindValueFrom();
    const active = this.kindButtonTargets.find((button) => button.dataset.kindValue === kind);
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
    if (value === "payment_method" || value === "payment_platform") return value;
    return "category";
  }
}

const SEGMENTED_ACTIVE_CLASS = "text-foreground";
const SEGMENTED_INACTIVE_CLASS = "text-muted-foreground";

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
    requestAnimationFrame(() => {
      requestAnimationFrame(() => this.#positionIndicator());
    });
  }

  disconnect() {
    window.removeEventListener("resize", this._onResize);
  }

  pickKind(event) {
    this.sync(event);
  }

  sync(event) {
    const kind = this.#kindValueFrom(event);

    if (this.hasKindSelectTarget && this.kindSelectTarget.value !== kind) {
      this.kindSelectTarget.value = kind;
    }

    if (this.hasCategoryPanelTarget) {
      this.categoryPanelTarget.classList.toggle("hidden", kind !== "category");
    }
    if (this.hasPaymentMethodPanelTarget) {
      this.paymentMethodPanelTarget.classList.toggle("hidden", kind !== "payment_method");
    }
    if (this.hasPaymentPlatformPanelTarget) {
      this.paymentPlatformPanelTarget.classList.toggle("hidden", kind !== "payment_platform");
    }

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
    this.indicatorTarget.style.left = `${left}px`;
    this.indicatorTarget.style.translate = "none";
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

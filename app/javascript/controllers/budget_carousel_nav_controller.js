import { Controller } from "@hotwired/stimulus";

/** Prev/next controls for budget carousels (mobile bar + desktop side arrows). */
export default class extends Controller {
  static targets = ["status", "prevButton", "nextButton"];

  connect() {
    this.carouselRoot = this.element.querySelector(
      '[data-controller*="ruby-ui--carousel"]'
    );
    this._onSlideChange = this.#updateStatus.bind(this);
    this.carouselRoot?.addEventListener(
      "ruby-ui--carousel:slide-change",
      this._onSlideChange
    );
    this.#updateStatus();
  }

  disconnect() {
    this.carouselRoot?.removeEventListener(
      "ruby-ui--carousel:slide-change",
      this._onSlideChange
    );
  }

  prev(event) {
    event.preventDefault();
    this.#carouselController()?.scrollPrev();
  }

  next(event) {
    event.preventDefault();
    this.#carouselController()?.scrollNext();
  }

  #carouselController() {
    if (!this.carouselRoot) return null;
    return this.application.getControllerForElementAndIdentifier(
      this.carouselRoot,
      "ruby-ui--carousel"
    );
  }

  #updateStatus() {
    const embla = this.#carouselController()?.carousel;
    if (!embla) {
      if (this.hasStatusTarget) this.statusTarget.textContent = "";
      return;
    }

    const total = embla.scrollSnapList().length;
    const index = embla.selectedScrollSnap();
    if (this.hasStatusTarget) {
      if (total <= 1) {
        this.statusTarget.textContent = total === 1 ? "第 1 筆" : "";
      } else {
        this.statusTarget.textContent = `第 ${index + 1}／${total} 筆`;
      }
    }

    const canPrev = embla.canScrollPrev();
    const canNext = embla.canScrollNext();
    this.prevButtonTargets.forEach((button) => {
      button.disabled = !canPrev;
    });
    this.nextButtonTargets.forEach((button) => {
      button.disabled = !canNext;
    });
  }
}

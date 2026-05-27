import { Controller } from "@hotwired/stimulus";

/** Mobile-friendly prev/next controls for budget carousels. */
export default class extends Controller {
  static targets = ["status"];

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
    if (!this.hasStatusTarget) return;
    const embla = this.#carouselController()?.carousel;
    if (!embla) {
      this.statusTarget.textContent = "";
      return;
    }

    const total = embla.scrollSnapList().length;
    const index = embla.selectedScrollSnap();
    if (total <= 1) {
      this.statusTarget.textContent = total === 1 ? "第 1 筆" : "";
      return;
    }

    this.statusTarget.textContent = `第 ${index + 1}／${total} 筆`;
  }
}

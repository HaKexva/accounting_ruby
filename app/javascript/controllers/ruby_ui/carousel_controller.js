import { Controller } from "@hotwired/stimulus";
import EmblaCarousel from 'embla-carousel'

const DEFAULT_OPTIONS = {
  loop: true
}

export default class extends Controller {
  static values = {
    options: {
      type: Object,
      default: {},
    },
    initialIndex: Number,
  }
  static targets = ["viewport", "nextButton", "prevButton"]

  #viewportResizeObserver = null;
  #lastViewportWidth = 0;

  connect() {
    this.initCarousel(this.#mergedOptions);
    this.#setupViewportResizeObserver();
  }

  disconnect() {
    this.#viewportResizeObserver?.disconnect();
    this.#viewportResizeObserver = null;
    this.destroyCarousel();
  }

  initCarousel(options, plugins = []) {
    this.carousel = EmblaCarousel(this.viewportTarget, options, plugins)

    this.carousel.on("init", () => {
      this.#applyInitialIndex()
      this.#onCarouselState()
    })
    this.carousel.on("reInit", this.#onCarouselState.bind(this))
    this.carousel.on("select", this.#onCarouselState.bind(this))
  }

  #setupViewportResizeObserver() {
    if (typeof ResizeObserver === "undefined") return

    const viewport = this.viewportTarget
    this.#lastViewportWidth = Math.round(viewport.getBoundingClientRect().width)

    this.#viewportResizeObserver = new ResizeObserver((entries) => {
      const entry = entries[0]
      if (!entry || !this.carousel) return

      const w = Math.round(entry.contentRect.width)
      const prev = this.#lastViewportWidth
      this.#lastViewportWidth = w

      if (prev === 0 && w > 0) {
        this.carousel.reInit()
        requestAnimationFrame(() => this.#applyInitialIndex())
      }
    })

    this.#viewportResizeObserver.observe(viewport)
  }

  destroyCarousel() {
    if (!this.carousel) return

    this.carousel.slideNodes().forEach((slide) => slide.removeAttribute("inert"))
    this.carousel.destroy()
  }

  scrollNext() {
    this.carousel.scrollNext()
  }

  scrollPrev() {
    this.carousel.scrollPrev()
  }

  /** Jump to a slide index (used by coordinating controllers). */
  scrollToIndex(index) {
    if (!this.carousel) return
    const snaps = this.carousel.scrollSnapList()
    if (!snaps?.length) return
    const i = Math.min(Math.max(0, index), snaps.length - 1)
    this.carousel.scrollTo(i)
  }

  keydownScrollNext(event) {
    if (this.#isEditableTarget(event.target)) return
    event.preventDefault()
    this.scrollNext()
  }

  keydownScrollPrev(event) {
    if (this.#isEditableTarget(event.target)) return
    event.preventDefault()
    this.scrollPrev()
  }

  #isEditableTarget(node) {
    if (!(node instanceof Element)) return false

    const tag = node.tagName
    if (tag === "TEXTAREA" || tag === "SELECT") return true
    if (node.isContentEditable) return true
    if (tag !== "INPUT") return false

    const type = node.type?.toLowerCase() ?? "text"
    return !["button", "checkbox", "hidden", "radio", "submit", "reset"].includes(type)
  }

  #applyInitialIndex() {
    if (!this.hasInitialIndexValue) return
    const index = this.initialIndexValue
    requestAnimationFrame(() => this.scrollToIndex(index))
  }

  #onCarouselState() {
    this.#updateControls()
    this.#syncSlideInertState()
    this.#dispatchSlideChange()
  }

  #dispatchSlideChange() {
    if (!this.carousel) return
    this.dispatch("slide-change", {
      prefix: "ruby-ui--carousel",
      bubbles: true,
      detail: { index: this.carousel.selectedScrollSnap() },
    })
  }

  /** Keeps off-screen slides out of the tab order (and non-interactive). */
  #syncSlideInertState() {
    const slides = this.carousel.slideNodes()
    if (!slides.length) return

    let selected = this.carousel.selectedScrollSnap()
    if (!Number.isFinite(selected) || selected < 0) selected = 0
    if (selected >= slides.length) selected = slides.length - 1

    slides.forEach((slide, index) => {
      if (index === selected) slide.removeAttribute("inert")
      else slide.setAttribute("inert", "")
    })
  }

  #updateControls() {
    this.#toggleButtonsDisabledState(this.nextButtonTargets, !this.carousel.canScrollNext())
    this.#toggleButtonsDisabledState(this.prevButtonTargets, !this.carousel.canScrollPrev())
  }

  #toggleButtonsDisabledState(buttons, isDisabled) {
    buttons.forEach((button) => button.disabled = isDisabled)
  }

  get #mergedOptions() {
    return {
      ...DEFAULT_OPTIONS,
      ...this.optionsValue
    }
  }
}

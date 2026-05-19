import { Controller } from "@hotwired/stimulus";

/**
 * Mobile (<lg): when 金額 inputs are focused and the summary panel is scrolled
 * under the app header, pin the panel under the header (like accounting/expense.md).
 * Uses visualViewport so the bar stays usable when the software keyboard opens.
 */
export default class extends Controller {
  static targets = ["stickyPanel", "amountInput"];

  #mq = null;
  #scrollRoot = null;
  #placeholder = null;
  #pinned = false;
  #amountFocused = false;
  #pinnedClass = [
    "fixed",
    "z-20",
    "left-0",
    "right-0",
    "w-full",
    "max-w-none",
    "border-b",
    "border-border/60",
    "bg-background",
    "shadow-md",
    "px-4",
    "pb-3",
    "pt-2",
    "sm:px-6",
  ];

  connect() {
    if (!this.hasStickyPanelTarget || this.amountInputTargets.length === 0) return;

    this.#mq = window.matchMedia("(max-width: 1023px)");
    this.#scrollRoot =
      this.stickyPanelTarget.closest("#app-main-scroll") ||
      document.getElementById("app-main-scroll");

    this.element.addEventListener("focusin", this.#onFocusIn, true);
    this.element.addEventListener("focusout", this.#onFocusOut, true);

    this.#scrollRoot?.addEventListener("scroll", this.#onScroll, { passive: true });
    window.addEventListener("resize", this.#onResize, { passive: true });
    window.visualViewport?.addEventListener("resize", this.#onViewportChange, { passive: true });
    window.visualViewport?.addEventListener("scroll", this.#onViewportChange, { passive: true });
    this.#mq.addEventListener("change", this.#onMqChange);
  }

  disconnect() {
    if (!this.hasStickyPanelTarget || this.amountInputTargets.length === 0) return;

    this.element.removeEventListener("focusin", this.#onFocusIn, true);
    this.element.removeEventListener("focusout", this.#onFocusOut, true);
    this.#scrollRoot?.removeEventListener("scroll", this.#onScroll);
    window.removeEventListener("resize", this.#onResize);
    window.visualViewport?.removeEventListener("resize", this.#onViewportChange);
    window.visualViewport?.removeEventListener("scroll", this.#onViewportChange);
    this.#mq?.removeEventListener("change", this.#onMqChange);
    this.#teardownPinned();
    this.#placeholder?.remove();
    this.#placeholder = null;
  }

  #onMqChange = () => {
    if (!this.#isMobile()) this.#teardownPinned();
    else this.#updateStickyState();
  };

  #onResize = () => {
    this.#updateStickyState();
    this.#updatePinnedTop();
  };

  #onScroll = () => this.#updateStickyState();

  #onViewportChange = () => {
    if (!this.#pinned) return;
    this.#updatePinnedTop();
  };

  #onFocusIn = (ev) => {
    if (!this.#isMobile()) return;
    if (!this.amountInputTargets.includes(ev.target)) return;
    this.#amountFocused = true;
    this.#ensurePlaceholder();
    this.#updateStickyState();
  };

  #onFocusOut = () => {
    window.requestAnimationFrame(() => {
      const active = document.activeElement;
      const stillAmount =
        active &&
        this.amountInputTargets.some((el) => el === active || el.contains(active));
      if (stillAmount) return;
      this.#amountFocused = false;
      this.#teardownPinned();
    });
  };

  #isMobile() {
    return this.#mq?.matches ?? false;
  }

  #headerEl() {
    return document.getElementById("app-mobile-header");
  }

  #headerBottom() {
    const h = this.#headerEl();
    if (!h) return 56;
    return h.getBoundingClientRect().bottom;
  }

  #isSummarySlotVisible() {
    const el =
      this.#pinned && this.#placeholder?.isConnected
        ? this.#placeholder
        : this.stickyPanelTarget;
    const rect = el.getBoundingClientRect();
    const topBound = this.#headerBottom();
    return rect.top >= topBound - 2;
  }

  #ensurePlaceholder() {
    if (this.#placeholder?.isConnected) return;
    const panel = this.stickyPanelTarget;
    const ph = document.createElement("div");
    ph.setAttribute("aria-hidden", "true");
    ph.className = "expenditure-mobile-summary-placeholder hidden";
    panel.parentNode?.insertBefore(ph, panel);
    this.#placeholder = ph;
  }

  #updateStickyState = () => {
    if (!this.#isMobile()) {
      this.#teardownPinned();
      return;
    }
    if (!this.#amountFocused) {
      this.#teardownPinned();
      return;
    }

    const shouldPin = !this.#isSummarySlotVisible();

    if (shouldPin && !this.#pinned) {
      const panel = this.stickyPanelTarget;
      const ph = this.#placeholder;
      if (!ph) return;
      ph.style.height = `${panel.offsetHeight}px`;
      ph.classList.remove("hidden");
      this.#pinnedClass.forEach((c) => panel.classList.add(c));
      this.#pinned = true;
      this.#updatePinnedTop();
    } else if (!shouldPin && this.#pinned) {
      this.#teardownPinned();
    } else if (this.#pinned) {
      const ph = this.#placeholder;
      const panel = this.stickyPanelTarget;
      if (ph) ph.style.height = `${panel.offsetHeight}px`;
      this.#updatePinnedTop();
    }
  };

  #updatePinnedTop() {
    if (!this.#pinned) return;
    const panel = this.stickyPanelTarget;
    const headerH = Math.ceil(this.#headerBottom());
    const vv = window.visualViewport;
    if (vv && vv.height < window.innerHeight * 0.72) {
      panel.style.top = `${Math.max(vv.offsetTop, headerH)}px`;
    } else {
      panel.style.top = `${headerH}px`;
    }
  }

  #teardownPinned() {
    const panel = this.stickyPanelTarget;
    this.#pinnedClass.forEach((c) => panel.classList.remove(c));
    panel.style.top = "";
    this.#pinned = false;
    if (this.#placeholder) {
      this.#placeholder.style.height = "";
      this.#placeholder.classList.add("hidden");
    }
  };
}

import { Controller } from "@hotwired/stimulus";

/**
 * Mobile (<lg): when 金額 inputs are focused and the summary panel is scrolled
 * under the app header, pin the panel under the header (like accounting/expense.md).
 * Uses visualViewport so the bar stays usable when the software keyboard opens.
 */
export default class extends Controller {
  static targets = [
    "stickyPanel",
    "amountInput",
    "statsRow",
    "chip",
    "chipLabel",
    "chipValue",
    "chartPanel",
    "summaryHint",
    "summaryHeader",
  ];

  #mq = null;
  #scrollRoot = null;
  #placeholder = null;
  #pinned = false;
  #amountFocused = false;
  #compact = false;
  #scrollTimer = null;
  #pinnedClass = [
    "fixed",
    "z-[60]",
    "left-0",
    "right-0",
    "w-full",
    "max-w-none",
    "border-b",
    "border-border/60",
    "bg-background/95",
    "backdrop-blur-md",
    "supports-[backdrop-filter]:bg-background/90",
    "shadow-md",
    "px-4",
    "pb-3",
    "pt-2",
    "sm:px-6",
  ];

  #compactPanelClass = ["pb-2"];

  #compactStatsRowAdd = ["flex-nowrap", "justify-between", "gap-2"];
  #compactStatsRowRemove = ["flex-wrap", "justify-center"];

  #compactChipAdd = ["aspect-square", "p-2", "min-w-0"];
  #compactChipRemove = ["px-2.5", "py-2.5", "sm:px-2.5", "sm:py-3", "basis-0"];

  #compactLabelAdd = ["text-[10px]", "leading-none"];
  #compactLabelRemove = ["sm:text-xs"];

  #compactValueAdd = ["mt-0.5", "text-sm", "leading-none"];
  #compactValueRemove = ["sm:text-base"];

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
    window.clearTimeout(this.#scrollTimer);
    this.#scrollTimer = null;
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
    this.#updateCompactState();
    this.#scheduleEnsureAmountVisible();
  };

  #onScroll = () => this.#updateStickyState();

  #onViewportChange = () => {
    this.#updateCompactState();
    if (this.#pinned) this.#updatePinnedTop();
    this.#scheduleEnsureAmountVisible();
  };

  #onFocusIn = (ev) => {
    if (!this.#isMobile()) return;
    if (!this.amountInputTargets.includes(ev.target)) return;
    this.#amountFocused = true;
    this.#ensurePlaceholder();
    this.#updateCompactState();
    this.#updateStickyState();
    this.#scheduleEnsureAmountVisible();
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
      this.#updateCompactState();
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

  #keyboardLikely() {
    const vv = window.visualViewport;
    return Boolean(vv && vv.height < window.innerHeight * 0.72);
  }

  #activeAmountInput() {
    const active = document.activeElement;
    if (!active) return null;
    return this.amountInputTargets.find((el) => el === active || el.contains(active)) ?? null;
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
      this.#updateCompactState();
      this.#scheduleEnsureAmountVisible();
    } else if (!shouldPin && this.#pinned) {
      this.#teardownPinned();
    } else if (this.#pinned) {
      const ph = this.#placeholder;
      const panel = this.stickyPanelTarget;
      if (ph) ph.style.height = `${panel.offsetHeight}px`;
      this.#updatePinnedTop();
      this.#updateCompactState();
    }
  };

  #updatePinnedTop() {
    if (!this.#pinned) return;
    const panel = this.stickyPanelTarget;
    const vv = window.visualViewport;
    if (vv && this.#keyboardLikely()) {
      panel.style.top = `${vv.offsetTop}px`;
    } else {
      panel.style.top = `${this.#headerBottom()}px`;
    }
  }

  #shouldCompact() {
    if (!this.#isMobile() || !this.#amountFocused) return false;
    if (this.#keyboardLikely()) return true;

    if (!this.#pinned) return false;

    const vv = window.visualViewport;
    const headerBottom = this.#headerBottom();
    const viewportH = vv ? vv.height : window.innerHeight;
    const available = Math.max(0, viewportH - headerBottom - 8);
    const panelH = this.stickyPanelTarget.offsetHeight || 0;
    return panelH > available * 0.55;
  }

  #updateCompactState() {
    const should = this.#shouldCompact();
    if (should === this.#compact) return;
    this.#compact = should;
    this.#applyCompact(this.#compact);
    if (this.#placeholder && this.#pinned) {
      this.#placeholder.style.height = `${this.stickyPanelTarget.offsetHeight}px`;
    }
    if (this.#amountFocused) this.#scheduleEnsureAmountVisible();
  }

  #applyCompact(on) {
    const panel = this.stickyPanelTarget;
    const statsRow = this.hasStatsRowTarget ? this.statsRowTarget : null;

    if (on) this.#compactPanelClass.forEach((c) => panel.classList.add(c));
    else this.#compactPanelClass.forEach((c) => panel.classList.remove(c));

    if (this.hasSummaryHeaderTarget) {
      this.summaryHeaderTarget.classList.toggle("hidden", on);
    }
    if (this.hasChartPanelTarget) this.chartPanelTarget.classList.toggle("hidden", on);
    if (this.hasSummaryHintTarget) this.summaryHintTarget.classList.toggle("hidden", on);

    if (statsRow) {
      this.#compactStatsRowRemove.forEach((c) => statsRow.classList.toggle(c, !on));
      this.#compactStatsRowAdd.forEach((c) => statsRow.classList.toggle(c, on));
    }

    this.chipTargets.forEach((chip) => {
      this.#compactChipRemove.forEach((c) => chip.classList.toggle(c, !on));
      this.#compactChipAdd.forEach((c) => chip.classList.toggle(c, on));
      chip.classList.toggle("flex-1", !on);
      chip.classList.toggle("flex-none", on);
      chip.style.flexBasis = on ? "33.3333%" : "";
    });

    this.chipLabelTargets.forEach((el) => {
      this.#compactLabelRemove.forEach((c) => el.classList.toggle(c, !on));
      this.#compactLabelAdd.forEach((c) => el.classList.toggle(c, on));
    });

    this.chipValueTargets.forEach((el) => {
      this.#compactValueRemove.forEach((c) => el.classList.toggle(c, !on));
      this.#compactValueAdd.forEach((c) => el.classList.toggle(c, on));
    });
  }

  #scheduleEnsureAmountVisible() {
    if (!this.#amountFocused) return;
    window.clearTimeout(this.#scrollTimer);
    this.#scrollTimer = window.setTimeout(() => this.#ensureAmountInputVisible(), 320);
    window.requestAnimationFrame(() => this.#ensureAmountInputVisible());
  }

  #ensureAmountInputVisible() {
    if (!this.#isMobile() || !this.#amountFocused) return;

    const input = this.#activeAmountInput();
    if (!input) return;

    const vv = window.visualViewport;
    const scrollRoot = this.#scrollRoot;
    if (!vv || !scrollRoot) {
      input.scrollIntoView({ block: "nearest", behavior: "smooth" });
      return;
    }

    const gap = 12;
    const barBottom = this.#pinned
      ? this.stickyPanelTarget.getBoundingClientRect().bottom
      : this.#headerBottom();
    const visibleTop = vv.offsetTop;
    const visibleBottom = vv.offsetTop + vv.height;
    const minTop = Math.max(visibleTop, barBottom) + gap;
    const maxBottom = visibleBottom - gap;
    const rect = input.getBoundingClientRect();

    if (rect.top < minTop) {
      scrollRoot.scrollBy({ top: rect.top - minTop, behavior: "smooth" });
    } else if (rect.bottom > maxBottom) {
      scrollRoot.scrollBy({ top: rect.bottom - maxBottom, behavior: "smooth" });
    }
  }

  #teardownPinned() {
    const panel = this.stickyPanelTarget;
    if (this.#compact) {
      this.#compact = false;
      this.#applyCompact(false);
    }
    this.#pinnedClass.forEach((c) => panel.classList.remove(c));
    panel.style.top = "";
    this.#pinned = false;
    if (this.#placeholder) {
      this.#placeholder.style.height = "";
      this.#placeholder.classList.add("hidden");
    }
  };
}

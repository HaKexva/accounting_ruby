import { Controller } from "@hotwired/stimulus";

/**
 * Mobile (<lg): when 金額 inputs are focused and the summary panel is scrolled
 * under the app header, pin the panel under the header (like accounting/expense.md).
 * Uses visualViewport so the bar stays usable when the software keyboard opens.
 *
 * Scroll corrections use instant scroll + hysteresis; while focused we do not
 * unpin (avoids pin/unpin bounce). On blur we reset window scroll so iOS does
 * not leave the mobile header above the visual viewport (only once the
 * keyboard is closed — resetting while it is open makes iOS re-scroll and
 * fight us).
 *
 * While pinned, the summary's own scroll wrapper is set to overflow visible so
 * touch scrolls on the fixed bar chain to #app-main-scroll instead of being
 * swallowed by the (possibly unscrollable) wrapper. While the keyboard is
 * open we pad #app-main-scroll's bottom by the keyboard height so the submit
 * buttons stay reachable on iOS, which ignores interactive-widget=resizes-content.
 */
export default class extends Controller {
  static targets = [
    "stickyPanel",
    "scrollWrap",
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
  #ensuringVisible = false;
  #keyboardWasOpen = false;
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
    window.visualViewport?.addEventListener("resize", this.#onViewportResize, { passive: true });
    window.visualViewport?.addEventListener("scroll", this.#onViewportScroll, { passive: true });
    this.#mq.addEventListener("change", this.#onMqChange);
  }

  disconnect() {
    if (!this.hasStickyPanelTarget || this.amountInputTargets.length === 0) return;

    this.element.removeEventListener("focusin", this.#onFocusIn, true);
    this.element.removeEventListener("focusout", this.#onFocusOut, true);
    this.#scrollRoot?.removeEventListener("scroll", this.#onScroll);
    window.removeEventListener("resize", this.#onResize);
    window.visualViewport?.removeEventListener("resize", this.#onViewportResize);
    window.visualViewport?.removeEventListener("scroll", this.#onViewportScroll);
    this.#mq?.removeEventListener("change", this.#onMqChange);
    window.clearTimeout(this.#scrollTimer);
    this.#scrollTimer = null;
    if (this.#scrollRoot) this.#scrollRoot.style.paddingBottom = "";
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
  };

  #onScroll = () => {
    if (this.#ensuringVisible) return;
    this.#updateStickyState();
  };

  #onViewportResize = () => {
    const keyboardOpen = this.#keyboardLikely();
    const keyboardJustOpened = keyboardOpen && !this.#keyboardWasOpen;
    const keyboardJustClosed = !keyboardOpen && this.#keyboardWasOpen;
    this.#keyboardWasOpen = keyboardOpen;

    this.#updateKeyboardPadding();
    this.#updateCompactState();
    if (this.#pinned) this.#updatePinnedTop();

    if (keyboardJustClosed && !this.#amountFocused) {
      this.#restoreLayoutViewport();
      return;
    }

    // Only re-check visibility when the keyboard opens (viewport height change),
    // not on every visualViewport scroll — that caused up/down bounce while typing.
    if (this.#amountFocused && keyboardJustOpened) {
      this.#scheduleEnsureAmountVisible();
    }
  };

  #onViewportScroll = () => {
    if (!this.#pinned) return;
    this.#updatePinnedTop();
  };

  #onFocusIn = (ev) => {
    if (!this.#isMobile()) return;
    if (!this.amountInputTargets.includes(ev.target)) return;
    this.#amountFocused = true;
    this.#keyboardWasOpen = this.#keyboardLikely();
    this.#ensurePlaceholder();
    this.#updateCompactState();
    this.#updateStickyState();
    this.#scheduleEnsureAmountVisible();
  };

  #onFocusOut = () => {
    // setTimeout, not rAF: rAF stalls when the page isn't rendering frames
    // (occluded window, iOS throttling) and the bar would stay pinned forever.
    window.setTimeout(() => {
      const active = document.activeElement;
      const stillAmount =
        active &&
        this.amountInputTargets.some((el) => el === active || el.contains(active));
      if (stillAmount) return;
      this.#amountFocused = false;
      this.#teardownPinned();
      this.#updateCompactState();
      this.#restoreLayoutViewport();
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

    // Once pinned while typing, stay pinned until blur — unpinning mid-focus
    // fights scroll-into-view and causes jitter.
    if (this.#pinned) {
      const ph = this.#placeholder;
      const panel = this.stickyPanelTarget;
      if (ph) ph.style.height = `${panel.offsetHeight}px`;
      this.#updatePinnedTop();
      this.#updateCompactState();
      return;
    }

    if (!this.#isSummarySlotVisible()) {
      const panel = this.stickyPanelTarget;
      const ph = this.#placeholder;
      if (!ph) return;
      ph.style.height = `${panel.offsetHeight}px`;
      ph.classList.remove("hidden");
      this.#pinnedClass.forEach((c) => panel.classList.add(c));
      // Inline style, not just the `fixed` class: the panel also carries
      // `relative`, and in the built Tailwind CSS `.relative` comes after
      // `.fixed`, so the class alone loses and the panel never actually pins.
      panel.style.position = "fixed";
      this.#pinned = true;
      this.#setWrapOverflowVisible(true);
      this.#updatePinnedTop();
      this.#updateCompactState();
    }
  };

  /**
   * While the panel is fixed, its DOM home is still the summary scroll
   * wrapper — touch scrolls on the pinned bar would target that wrapper and
   * go nowhere. Overflow visible turns it into a non-scroll-container so the
   * gesture chains up to #app-main-scroll. The pinned panel is out of flow
   * and the placeholder keeps the wrapper's height, so nothing shifts.
   */
  #setWrapOverflowVisible(on) {
    if (!this.hasScrollWrapTarget) return;
    this.scrollWrapTarget.style.overflowY = on ? "visible" : "";
  }

  /**
   * iOS Safari ignores interactive-widget=resizes-content: the keyboard
   * overlays the layout viewport, so #app-main-scroll's bottom (the submit
   * buttons) can end up unreachable behind it. Pad the scroller by the
   * keyboard height while it is open.
   */
  #updateKeyboardPadding() {
    const root = this.#scrollRoot;
    if (!root) return;
    const vv = window.visualViewport;
    if (this.#isMobile() && vv && this.#keyboardLikely()) {
      root.style.paddingBottom = `${Math.max(0, window.innerHeight - vv.height)}px`;
    } else {
      root.style.paddingBottom = "";
    }
  }

  #updatePinnedTop() {
    if (!this.#pinned) return;
    const panel = this.stickyPanelTarget;
    const headerH = Math.ceil(this.#headerBottom());
    const vv = window.visualViewport;
    if (vv && this.#keyboardLikely()) {
      // Follow the visual viewport when iOS scrolls the layout under the keyboard.
      panel.style.top = `${Math.max(vv.offsetTop, 0)}px`;
    } else {
      panel.style.top = `${headerH}px`;
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
    // Wait for keyboard / layout to settle; one correction only (no rAF + timeout pair).
    this.#scrollTimer = window.setTimeout(() => this.#ensureAmountInputVisible(), 280);
  }

  #ensureAmountInputVisible() {
    if (!this.#isMobile() || !this.#amountFocused || this.#ensuringVisible) return;

    const input = this.#activeAmountInput();
    if (!input) return;

    const vv = window.visualViewport;
    const scrollRoot = this.#scrollRoot;
    if (!vv || !scrollRoot) {
      input.scrollIntoView({ block: "nearest", behavior: "auto" });
      return;
    }

    const gap = 12;
    const slack = 24;
    const barBottom = this.#pinned
      ? this.stickyPanelTarget.getBoundingClientRect().bottom
      : this.#headerBottom();
    const visibleTop = vv.offsetTop;
    const visibleBottom = vv.offsetTop + vv.height;
    const minTop = Math.max(visibleTop, barBottom) + gap;
    const maxBottom = visibleBottom - gap;
    const rect = input.getBoundingClientRect();

    let delta = 0;
    if (rect.top < minTop - slack) {
      delta = rect.top - minTop;
    } else if (rect.bottom > maxBottom + slack) {
      delta = rect.bottom - maxBottom;
    }
    if (delta === 0) return;

    this.#ensuringVisible = true;
    scrollRoot.scrollBy({ top: delta, behavior: "auto" });
    // setTimeout, not rAF: a stalled rAF would leave #ensuringVisible true and
    // #onScroll ignoring every scroll from then on.
    window.setTimeout(() => {
      this.#ensuringVisible = false;
      this.#updateStickyState();
    });
  }

  /**
   * iOS often leaves window/document scrolled after the keyboard closes.
   * Skip while the keyboard is still open (focus moved to another field) —
   * resetting then makes iOS re-scroll to the new field and the page jumps.
   * The keyboardJustClosed branch of #onViewportResize restores later.
   */
  #restoreLayoutViewport() {
    if (this.#keyboardLikely()) return;
    window.scrollTo(0, 0);
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;
  }

  #teardownPinned() {
    const panel = this.stickyPanelTarget;
    this.#setWrapOverflowVisible(false);
    if (this.#compact) {
      this.#compact = false;
      this.#applyCompact(false);
    }
    this.#pinnedClass.forEach((c) => panel.classList.remove(c));
    panel.style.position = "";
    panel.style.top = "";
    this.#pinned = false;
    if (this.#placeholder) {
      this.#placeholder.style.height = "";
      this.#placeholder.classList.add("hidden");
    }
  };
}

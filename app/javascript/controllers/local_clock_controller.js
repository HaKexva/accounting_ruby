import { Controller } from "@hotwired/stimulus";

/** Renders the current instant in the browser's local timezone (updates every second). */
export default class extends Controller {
  connect() {
    this.tick();
    this.timer = window.setInterval(() => this.tick(), 1000);
  }

  disconnect() {
    window.clearInterval(this.timer);
  }

  tick() {
    const now = new Date();
    this.element.dateTime = now.toISOString();

    const pad = (n) => String(n).padStart(2, "0");
    const y = now.getFullYear();
    const m = pad(now.getMonth() + 1);
    const d = pad(now.getDate());
    const h = pad(now.getHours());
    const min = pad(now.getMinutes());
    const s = pad(now.getSeconds());

    this.element.textContent = `${y}/${m}/${d} ${h}:${min}:${s}`;
  }
}

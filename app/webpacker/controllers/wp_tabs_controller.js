import { Controller } from "stimulus";

// Makes tabs of the WordPress block editor work without loading WordPress'
// JavaScript. Its markup follows the ARIA tabs pattern: buttons with
// `role="tab"` control panels via `aria-controls`. WordPress renders all
// panels hidden and relies on its own code to reveal the active one.
export default class extends Controller {
  connect() {
    this.element.querySelectorAll(".wp-block-tabs").forEach((tabs) => {
      this.select(tabs.querySelector('[role="tab"]'));
    });
  }

  activate(event) {
    this.select(event.target.closest('[role="tab"]'));
  }

  navigate(event) {
    const tab = event.target.closest('[role="tab"]');
    const step = { ArrowLeft: -1, ArrowRight: 1 }[event.key];
    if (!tab || !step) return;

    const tabs = Array.from(tab.closest(".wp-block-tabs").querySelectorAll('[role="tab"]'));
    const next = tabs[(tabs.indexOf(tab) + step + tabs.length) % tabs.length];

    this.select(next);
    next.focus();
    event.preventDefault();
  }

  select(tab) {
    if (!tab) return;

    tab
      .closest(".wp-block-tabs")
      .querySelectorAll('[role="tab"]')
      .forEach((other) => {
        const selected = other === tab;
        other.setAttribute("aria-selected", selected);
        other.tabIndex = selected ? 0 : -1;

        const panel = document.getElementById(other.getAttribute("aria-controls"));
        if (panel) panel.hidden = !selected;
      });
  }
}

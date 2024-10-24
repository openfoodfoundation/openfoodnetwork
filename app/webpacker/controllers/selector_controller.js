import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    window.addEventListener("click", this.closeOnClickOutside);
    this.computeItemsHeight();
  }

  disconnect() {
    window.removeEventListener("click", this.closeOnClickOutside);
  }

  initialize() {
    this.close();
  }

  toggle = (event) => {
    event.preventDefault();
    this.element.querySelector(".selector").classList.toggle("selector-close");
  };

  // Private
  closeOnClickOutside = (event) => {
    if (
      !this.element.contains(event.target) &&
      this.isVisible(this.element.querySelector(".selector-wrapper"))
    ) {
      this.close();
    }
  };

  computeItemsHeight = () => {
    const items = this.element.querySelector(".selector-items");
    const rect = items.getBoundingClientRect();
    items.style.maxHeight = `calc(100vh - ${rect.height}px)`;
  };

  isVisible = (element) => {
    const style = window.getComputedStyle(element);
    return style.display !== "none" && style.visibility !== "hidden";
  };

  close = () => {
    this.element.querySelector(".selector").classList.add("selector-close");
  };
}

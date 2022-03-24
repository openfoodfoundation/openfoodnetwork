import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  reflex = "SelectorComponent";

  connect() {
    super.connect();
    window.addEventListener("click", this.closeOnClickOutside);
    this.computeItemsHeight();
  }

  disconnect() {
    super.disconnect();
    window.removeEventListener("click", this.closeOnClickOutside);
  }

  afterReflex() {
    this.computeItemsHeight();
  }

  closeOnClickOutside = (event) => {
    if (
      !this.element.contains(event.target) &&
      this.isVisible(this.element.querySelector(".selector-wrapper"))
    ) {
      this.stimulate(`${this.reflex}#close`, this.element);
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
}
